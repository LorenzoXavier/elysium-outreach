namespace :import do
  desc "Import CRM CSV export(s) via CsvImporterService. Usage: rake import:crm_data[path/to/file.csv]"
  task :crm_data, [:path] => :environment do |_t, args|
    files =
      if args[:path]
        [args[:path]]
      else
        Dir.glob(Rails.root.join("db", "seed_data", "*.csv"))
      end

    if files.empty?
      puts "No CSV files found. Pass a path: rake import:crm_data[path/to/file.csv]"
      next
    end

    puts "Importing #{files.size} file(s): #{files.map { |f| File.basename(f) }.join(', ')}"

    result = CsvImporterService.new(files).call

    puts "Batch: #{result.import_batch_id}"
    puts "Created (unique): #{result.created}"
    puts "Flagged as potential duplicates: #{result.duplicates}"

    if result.errors.any?
      puts "Errors:"
      result.errors.each { |e| puts "  #{e.file_name} line #{e.row_number}: #{e.message}" }
    end
  end
end
