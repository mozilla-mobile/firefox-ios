#!/usr/bin/env ruby
#
#  ProcessHeader.rb
#  Magical Record
#
#  Created by Saul Mora on 11/14/11.
#  Copyright 2011 Magical Panda Software LLC. All rights reserved.
#


def processHeader(headerFile)
    unless headerFile.end_with? ".h"
        puts "#{headerFile} not a header"
        return
    end
        
    puts "Reading #{headerFile}"
    
    method_match_expression = /^(?<Start>[\+|\-]\s*\([a-zA-Z\s\*]*\)\s*)(?<MethodName>\w+)(?<End>\:?.*)/
    category_match_expression = /^\s*(?<Interface>@[[:alnum:]]+)\s*(?<ObjectName>[[:alnum:]]+)\s*(\((?<Category>\w+)\))?/
    
    lines = File.readlines(headerFile)
    non_prefixed_methods = []
    processed_methods_count = 0
    objects_to_process = ["NSManagedObject", "NSManagedObjectContext", "NSManagedObjectModel", "NSPersistentStoreCoordinator", "NSPersistentStore"]
    
    lines.each { |line|
        
        processed_line = nil
        if line.start_with?("@interface")
            matches = category_match_expression.match(line)
            if objects_to_process.include?(matches[:ObjectName])
                processed_line = "#{matches[:Interface]} #{matches[:ObjectName]} (#{matches[:Category]}ShortHand)"
            else
                puts "Skipping #{headerFile}"
                non_prefixed_methods = nil
                return
            end
        end
        
        if processed_line == nil
            matches = method_match_expression.match(line)

            if matches
                if matches[:MethodName].start_with?("MR_")
                    ++processed_methods_count
                    methodName = matches[:MethodName].sub("MR_", "")
                    processed_line = "#{matches[:Start]}#{methodName}#{matches[:End]}"

                else
                    puts "Skipping #{headerFile}"
                    non_prefixed_methods = nil
                    return
                end
            end
        end
        
        if processed_line == nil
            if line.start_with?("@end")
                processed_line = "@end"
            end
        end
        
        unless processed_line == nil
            #            puts "#{line} ----->  #{processed_line}"
            non_prefixed_methods << processed_line
        end
    }
    
    non_prefixed_methods 
end

def processDirectory(path)

    headers = File.join(path, "**", "*+*.h")
    processedHeaders = []
    
    Dir.glob(headers).each { |file|
        puts "Processing #{file}"
        
        processDirectory(file) if File.directory?(file)
        if file.end_with?(".h")
            processedHeaders << processHeader(file)
        end
    }

    processedHeaders
end

def generateHeaders(startingPoint)

    processedHeaders = []
    if startingPoint
        path = File.expand_path(startingPoint)
        
        if path.end_with?(".h")
            processedHeaders << processHeader(path)
        else
            puts "Processing Headers in #{path}"
            processedHeaders << processDirectory(path)
        end

    else
        processedHeaders << processDirectory(startingPoint || Dir.getwd())
    end
        
    processedHeaders
end


puts "Input dir: #{File.expand_path(ARGV[0])}"

output_file = ARGV[1]
puts "Output file: #{File.expand_path(output_file)}"

unless output_file
    puts "Need an output file specified"
    return
else
    puts "Genrating shorthand headers"
end

headers = generateHeaders(ARGV[0])

File.open(output_file, "w") { |file|
    file.write("#ifdef MR_SHORTHAND\n\n")
    file.write(headers.join("\n"))
    file.write("#endif\n\n")
}




