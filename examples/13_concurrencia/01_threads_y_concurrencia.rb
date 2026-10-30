# frozen_string_literal: true

# = Threads y Concurrencia
#
# Ruby ofrece soporte nativo para concurrencia mediante Threads. Este archivo
# cubre los fundamentos: creación de hilos, sincronización con Mutex, colas
# de productor/consumidor y los problemas clásicos de estado compartido.
#
# ⚠️  IMPORTANTE: CRuby (MRI) tiene un Global VM Lock (GVL/GIL) que impide
# la ejecución paralela real de código Ruby puro. Los hilos son útiles para
# I/O concurrente (red, disco), pero NO aceleran cómputo CPU-bound en MRI.
# JRuby y TruffleRuby SÍ permiten paralelismo real.

puts "=" * 70
puts " THREADS Y CONCURRENCIA EN RUBY"
puts "=" * 70

# ──────────────────────────────────────────────────────────────────────────────
# 1. Creación básica de hilos con Thread.new
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 1. Thread.new básico ──"

# Thread.new recibe un bloque que se ejecuta en un hilo separado
hilo = Thread.new do
  puts "  [Hilo secundario] Iniciando trabajo..."
  sleep(0.1)
  puts "  [Hilo secundario] Trabajo completado"
end

puts "  [Hilo principal] Esperando al hilo secundario..."

# join bloquea el hilo actual hasta que el hilo objetivo termine
hilo.join
puts "  [Hilo principal] Hilo secundario finalizado"

# ──────────────────────────────────────────────────────────────────────────────
# 2. Thread#value - obtener el resultado de un hilo
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 2. Thread#value ──"

# value implícitamente llama a join y retorna el último valor del bloque
hilo_calculo = Thread.new do
  suma = (1..100).reduce(:+)
  suma # Este es el valor que retorna el hilo
end

resultado = hilo_calculo.value
puts "  Suma de 1 a 100 calculada en otro hilo: #{resultado}"

# ──────────────────────────────────────────────────────────────────────────────
# 3. Múltiples hilos concurrentes
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 3. Múltiples hilos ──"

hilos = 5.times.map do |idx|
  Thread.new(idx) do |num|
    sleep(rand(0.05..0.15))
    puts "  Hilo #{num} completado"
    num * 10
  end
end

# Recoger todos los resultados
resultados = hilos.map(&:value)
puts "  Resultados: #{resultados.inspect}"

# ──────────────────────────────────────────────────────────────────────────────
# 4. Pasar argumentos a Thread.new
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 4. Argumentos a Thread.new ──"

# Los argumentos se pasan como parámetros de Thread.new y se reciben en el bloque.
# Esto es más seguro que capturar variables externas (evita problemas de closure).
nombre = "Ruby"
hilo_args = Thread.new(nombre, 3) do |lenguaje, version|
  puts "  Hilo recibió: lenguaje=#{lenguaje}, version=#{version}"
end

# Cambiar la variable externa NO afecta al hilo (ya se copió la referencia)
nombre = "Python"
hilo_args.join
puts "  Variable externa ahora es: #{nombre} (el hilo no se vio afectado)"

# ──────────────────────────────────────────────────────────────────────────────
# 5. ⚠️  Problema: Race Condition (condición de carrera)
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 5. Race Condition (demostración del problema) ──"

# EJEMPLO PELIGROSO: múltiples hilos modificando estado compartido sin protección
contador_inseguro = 0
hilos_race = 10.times.map do
  Thread.new do
    1000.times do
      # Leer, incrementar y escribir NO es atómico
      # Otro hilo puede leer el mismo valor antes de que se escriba
      contador_inseguro += 1
    end
  end
end

hilos_race.each(&:join)
puts "  Contador sin protección: #{contador_inseguro} (esperado: 10000)"
puts "  ⚠️  Si el valor es < 10000, ocurrió una race condition"
puts "  (En MRI puede dar 10000 por el GVL, pero NO es garantía)"

# ──────────────────────────────────────────────────────────────────────────────
# 6. Mutex - Solución a las race conditions
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 6. Mutex (exclusión mutua) ──"

# Mutex garantiza que solo un hilo ejecute la sección crítica a la vez
contador_seguro = 0
mutex = Mutex.new

hilos_mutex = 10.times.map do
  Thread.new do
    1000.times do
      mutex.synchronize do
        # Solo un hilo a la vez puede ejecutar este bloque
        contador_seguro += 1
      end
    end
  end
end

hilos_mutex.each(&:join)
puts "  Contador con Mutex: #{contador_seguro} (siempre 10000)"

# ──────────────────────────────────────────────────────────────────────────────
# 7. Mutex#synchronize vs lock/unlock manual
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 7. Mutex: synchronize vs lock/unlock ──"

candado = Mutex.new
recurso_compartido = []

# ✅ Preferir synchronize (libera el mutex automáticamente, incluso con excepciones)
hilo_sync = Thread.new do
  candado.synchronize do
    recurso_compartido << "dato_seguro"
  end
end

# ❌ lock/unlock manual es propenso a errores (olvidar unlock, excepciones)
hilo_manual = Thread.new do
  candado.lock
  begin
    recurso_compartido << "dato_manual"
  ensure
    candado.unlock # Siempre liberar en ensure
  end
end

[hilo_sync, hilo_manual].each(&:join)
puts "  Recurso compartido: #{recurso_compartido.inspect}"
puts "  ✅ Siempre preferir synchronize sobre lock/unlock manual"

# ──────────────────────────────────────────────────────────────────────────────
# 8. Deadlock - Qué evitar
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 8. Deadlock (concepto) ──"

puts "  Un deadlock ocurre cuando dos hilos esperan mutuamente por el"
puts "  mutex del otro. Ruby detecta algunos deadlocks y lanza una excepción."
puts ""
puts "  Ejemplo conceptual (NO ejecutado para evitar bloqueo):"
puts "    mutex_a, mutex_b = Mutex.new, Mutex.new"
puts "    Hilo 1: lock(a) → intenta lock(b)  ← bloqueado"
puts "    Hilo 2: lock(b) → intenta lock(a)  ← bloqueado → ¡DEADLOCK!"
puts ""
puts "  Solución: siempre adquirir mutexes en el mismo orden"

# ──────────────────────────────────────────────────────────────────────────────
# 9. Thread::Queue - Productor/Consumidor
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 9. Thread::Queue (productor/consumidor) ──"

# Thread::Queue es thread-safe, no necesita Mutex adicional
cola = Thread::Queue.new

# Productor: genera datos y los pone en la cola
productor = Thread.new do
  5.times do |idx|
    item = "item_#{idx}"
    cola << item # push (alias de <<, push, enq)
    puts "  [Productor] Generado: #{item}"
    sleep(0.02)
  end
  cola.close # Señal de que no habrá más datos
end

# Consumidor: procesa datos de la cola
consumidor = Thread.new do
  # Cuando la cola está cerrada y vacía, pop retorna nil
  while (item = cola.pop)
    puts "  [Consumidor] Procesando: #{item}"
    sleep(0.05)
  end
  puts "  [Consumidor] Cola cerrada, terminando"
end

[productor, consumidor].each(&:join)

# ──────────────────────────────────────────────────────────────────────────────
# 10. SizedQueue - Cola con capacidad limitada
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 10. SizedQueue (cola con límite) ──"

# SizedQueue bloquea al productor cuando la cola está llena (backpressure)
cola_limitada = Thread::SizedQueue.new(3) # Máximo 3 elementos

productor_lento = Thread.new do
  8.times do |idx|
    cola_limitada << "dato_#{idx}"
    puts "  [Productor] Encolado dato_#{idx} (tamaño: #{cola_limitada.size})"
  end
  cola_limitada.close
end

consumidor_rapido = Thread.new do
  while (dato = cola_limitada.pop)
    puts "  [Consumidor] Procesado: #{dato}"
    sleep(0.03)
  end
end

[productor_lento, consumidor_rapido].each(&:join)

# ──────────────────────────────────────────────────────────────────────────────
# 11. Thread-local variables
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 11. Variables locales al hilo ──"

# Thread#[]= almacena datos accesibles solo desde ese hilo
hilos_locales = 3.times.map do |idx|
  Thread.new do
    Thread.current[:id_hilo] = idx
    Thread.current[:nombre] = "Worker-#{idx}"
    sleep(0.01)
    puts "  Hilo #{Thread.current[:id_hilo]}: #{Thread.current[:nombre]}"
  end
end

hilos_locales.each(&:join)

# thread_variable_get/set son como Thread#[] pero con scope de Fiber
hilo_fiber = Thread.new do
  Thread.current.thread_variable_set(:config, "valor_fiber_local")
  val = Thread.current.thread_variable_get(:config)
  puts "  Fiber-local variable: #{val}"
end
hilo_fiber.join

# ──────────────────────────────────────────────────────────────────────────────
# 12. Manejo de excepciones en hilos
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 12. Excepciones en hilos ──"

# Por defecto, las excepciones en hilos son silenciosas hasta llamar a join/value
hilo_error = Thread.new do
  raise "¡Error en el hilo!"
end

begin
  hilo_error.join # La excepción se relanza aquí
rescue RuntimeError => e
  puts "  Excepción capturada del hilo: #{e.message}"
end

# Thread.abort_on_exception = true haría que cualquier excepción en un hilo
# termine todo el programa (útil para desarrollo/depuración)
puts "  Thread.abort_on_exception = #{Thread.abort_on_exception} (default: false)"

# También se puede configurar por hilo individual:
hilo_config = Thread.new { "sin error" }
hilo_config.abort_on_exception = false
hilo_config.join

# ──────────────────────────────────────────────────────────────────────────────
# 13. Thread#status y estados del hilo
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 13. Estados del hilo ──"

hilo_estado = Thread.new { sleep(0.2) }
puts "  Estado durante ejecución: #{hilo_estado.status.inspect}"  # "sleep" o "run"
puts "  ¿Está vivo?: #{hilo_estado.alive?}"

hilo_estado.join
puts "  Estado después de join: #{hilo_estado.status.inspect}"    # false (terminó normal)
puts "  ¿Está vivo?: #{hilo_estado.alive?}"

# Posibles valores de status:
#   "run"     → ejecutándose
#   "sleep"   → dormido (sleep, esperando I/O, Mutex, etc.)
#   "aborting"→ siendo abortado
#   false     → terminó normalmente
#   nil       → terminó con excepción

# ──────────────────────────────────────────────────────────────────────────────
# 14. Patrón: Pool de hilos simple
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 14. Pool de hilos simple ──"

def procesar_con_pool(tareas:, num_hilos:)
  cola_tareas = Thread::Queue.new
  resultados = Thread::Queue.new

  # Encolar todas las tareas
  tareas.each { |tarea| cola_tareas << tarea }
  cola_tareas.close

  # Crear workers
  workers = num_hilos.times.map do |worker_id|
    Thread.new do
      while (tarea = cola_tareas.pop)
        resultado = yield(tarea, worker_id)
        resultados << resultado
      end
    end
  end

  workers.each(&:join)
  resultados.close

  # Recoger resultados
  collected = []
  while (res = resultados.pop)
    collected << res
  end
  collected
end

tareas = (1..10).to_a
resultados_pool = procesar_con_pool(tareas: tareas, num_hilos: 3) do |tarea, worker_id|
  sleep(0.01) # Simula trabajo
  { tarea: tarea, resultado: tarea * 2, worker: worker_id }
end

puts "  Procesadas #{resultados_pool.size} tareas con pool de 3 hilos"
resultados_pool.first(3).each do |res|
  puts "  Tarea #{res[:tarea]} → #{res[:resultado]} (worker #{res[:worker]})"
end
puts "  ..."

# ──────────────────────────────────────────────────────────────────────────────
# 15. ConditionVariable - Señalización entre hilos
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 15. ConditionVariable ──"

mutex_cv = Mutex.new
condicion = ConditionVariable.new
datos_listos = false
dato_compartido = nil

hilo_preparador = Thread.new do
  sleep(0.05) # Simula preparación
  mutex_cv.synchronize do
    dato_compartido = "datos_procesados"
    datos_listos = true
    condicion.signal # Despierta a UN hilo esperando
    # condicion.broadcast despertaría a TODOS los hilos esperando
  end
end

hilo_esperador = Thread.new do
  mutex_cv.synchronize do
    condicion.wait(mutex_cv) until datos_listos
    puts "  Datos recibidos: #{dato_compartido}"
  end
end

[hilo_preparador, hilo_esperador].each(&:join)

# ──────────────────────────────────────────────────────────────────────────────
# 16. Ractor (Ruby 3.1+) - Paralelismo real (vista previa)
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 16. Ractor (paralelismo real, Ruby 3.1+) ──"

# Los Ractors permiten paralelismo real sin GVL, usando paso de mensajes.
# ⚠️  Ractor sigue siendo experimental en muchas versiones de Ruby.

begin
  ractor = Ractor.new(42) do |valor|
    valor * 2 # Cada Ractor tiene su propio espacio de memoria
  end

  puts "  Resultado del Ractor: #{ractor.take}"
  puts "  ✅ Ractors disponibles en esta versión de Ruby"
rescue StandardError => e
  puts "  ⚠️  Ractors no disponibles o experimentales: #{e.message}"
end

# ──────────────────────────────────────────────────────────────────────────────
# 17. Resumen de buenas prácticas
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 17. Resumen de buenas prácticas ──"
puts <<~RESUMEN
  ✅ Usar Mutex#synchronize en vez de lock/unlock manual
  ✅ Preferir Thread::Queue para comunicación entre hilos
  ✅ Pasar datos a Thread.new como argumentos, no capturar variables mutables
  ✅ Siempre hacer join o value en los hilos creados
  ✅ Manejar excepciones en hilos (se pierden silenciosamente sin join)
  ✅ Para paralelismo CPU-bound real, considerar Ractor o procesos separados
  ✅ Para I/O concurrente (HTTP, archivos), los hilos funcionan bien con GVL

  ❌ No modificar estado compartido sin Mutex
  ❌ No asumir orden de ejecución entre hilos
  ❌ No crear hilos infinitos sin mecanismo de parada
  ❌ No adquirir múltiples Mutexes en orden diferente (deadlock)
RESUMEN

puts "\n✅ Archivo 01_threads_y_concurrencia.rb ejecutado correctamente"
