# frozen_string_literal: true

# = Búsqueda binaria, detección de duplicados en O(n) y agrupación de anagramas

module Solutions
  module Intermediate
    module BinarySearchAndDuplicates
      module_function

      def binary_search(sorted_items, target)
        low = 0
        high = sorted_items.length - 1
        while low <= high
          mid = (low + high) / 2
          comparison = sorted_items[mid] <=> target
          return mid if comparison.zero?

          comparison.negative? ? low = mid + 1 : high = mid - 1
        end
        nil
      end

      def find_duplicates(items)
        seen = Set.new
        duplicates = Set.new
        items.each do |item|
          duplicates.add(item) unless seen.add?(item)
        end
        duplicates.to_a
      end

      def group_anagrams(words)
        groups = Hash.new { |hash, key| hash[key] = [] }
        words.each do |word|
          signature = word.to_s.downcase.chars.sort.join
          groups[signature] << word
        end
        groups.values
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  alg = Solutions::Intermediate::BinarySearchAndDuplicates
  puts "Binary search index: #{alg.binary_search([10, 20, 30, 40, 50], 40)}"
  puts "Duplicates: #{alg.find_duplicates([3, 1, 4, 1, 5, 3, 1]).inspect}"
  puts "Anagrams: #{alg.group_anagrams(%w[roma amor ramo gato toga]).inspect}"
end
