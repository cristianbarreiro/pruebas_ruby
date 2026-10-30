# Pool de trabajadores concurrente y seguro para hilos (Thread-Safe Worker Pool)

## Enunciado inequívoco
Implementa en `Solutions::Advanced::ThreadSafeWorkerPool` un grupo acotado de hilos trabajadores (*worker pool*) utilizando `Thread::Queue` y `Mutex` que ejecute tareas de forma concurrente, sincronice el acceso al estado compartido y capture los errores individuales de cada tarea en resultados estructurados `{ id:, value:, error: }` sin derribar los hilos del pool.

## Contexto del problema
Crear un hilo nuevo (`Thread.new`) por cada tarea cuando llegan miles de elementos agota los descriptores del sistema operativo y degrada el rendimiento por exceso de cambios de contexto. Por otro lado, en un pool de hilos compartido, si una tarea lanza una excepción no controlada, el hilo trabajador muere silenciosamente o bloquea el cierre del pool, y si varios hilos escriben resultados en un `Array` o `Hash` sin sincronización, se producen condiciones de carrera (*race conditions*).

## Requisitos funcionales
1. Definir `WorkerPool` dentro de `Solutions::Advanced::ThreadSafeWorkerPool`.
2. `WorkerPool.new(size: 4)` valida que `size` sea un entero mayor o igual a `1` (lanza `ArgumentError` si no lo es) e inicia los mecanismos de sincronización (`Thread::Queue` y `Mutex`).
3. `#schedule(job_id = nil, &block)` encola una tarea para ser ejecutada por el pool:
   - Si no se entrega un bloque, lanza `ArgumentError`.
   - Si el pool ya fue cerrado con `#shutdown`, lanza `RuntimeError`.
4. `#shutdown` envía las señales de parada a todos los hilos trabajadores, espera a que terminen (`Thread#join`) y devuelve el arreglo de resultados ordenado por el orden de encolado.
5. Cada resultado individual debe ser un hash con las claves `{ id:, value:, error: }`:
   - Si la tarea finaliza con éxito: `{ id: job_id, value: resultado, error: nil }`.
   - Si la tarea lanza una subclase de `StandardError`: `{ id: job_id, value: nil, error: excepcion }`, y el hilo trabajador continúa procesando las siguientes tareas de la cola.
6. `#stats` devuelve de forma segura para hilos `{ total:, succeeded:, failed: }`.
7. `WorkerPool.map(items, size: 4) { |item| ... }` ofrece un atajo de clase que procesa una colección completa y cierra el pool automáticamente.

## Restricciones técnicas
- Uso obligatorio de `Thread::Queue` para la distribución de trabajo y `Mutex` para proteger la escritura de resultados y contadores.
- Prohibido usar gemas externas como `concurrent-ruby`.

## Ejemplos de entrada y salida
```ruby
results = Solutions::Advanced::ThreadSafeWorkerPool::WorkerPool.map([10, 0, 5], size: 2) do |num|
  100 / num
end

results[0] # => { id: 0, value: 10, error: nil }
results[1][:error].class # => ZeroDivisionError
results[2] # => { id: 2, value: 20, error: nil }
```

## Casos límite
- Colección de tareas vacía: `#shutdown` o `.map([])` termina inmediatamente devolviendo `[]`.
- Número de trabajadores (`size`) mayor que la cantidad de tareas encoladas: todos los hilos sobrantes se cierran limpiamente al recibir su señal de parada.
- Todas las tareas lanzan excepciones: ningún hilo muere prematuramente y todas las excepciones quedan registradas en `:error`.

## Criterios de aceptación
- Ejecución concurrente verificable con múltiples hilos activos.
- Ausencia de condiciones de carrera al registrar decenas de tareas rápidas simultáneas.
- Conservación del orden de salida respecto al orden en que las tareas fueron programadas.

## Sugerencia de implementación
Asigna a cada tarea un índice incremental al encolarla y utiliza un símbolo centinela privado (por ejemplo, `STOP_SIGNAL = :__stop__`) encolado `size` veces dentro de `#shutdown` para que cada trabajador salga de su bucle `loop` de forma ordenada.
