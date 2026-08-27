# Seeds baseline outreach data from any CSV exports in db/seed_data
# (e.g. "Elysium CRM - Outreach.csv"), using the same CsvImporterService
# that powers the in-app multi-file upload. Safe to re-run: rows that
# already match an existing contact are flagged as potential duplicates
# rather than duplicated blindly.
csv_files = Dir.glob(Rails.root.join("db", "seed_data", "*.csv"))

if csv_files.empty?
  puts "No CSV files found in db/seed_data -- skipping baseline import."
else
  puts "Seeding from #{csv_files.size} file(s): #{csv_files.map { |f| File.basename(f) }.join(', ')}"

  result = CsvImporterService.new(csv_files).call

  puts "Batch #{result.import_batch_id}: #{result.created} unique, #{result.duplicates} potential duplicates"
  result.errors.each { |e| puts "  Error in #{e.file_name} line #{e.row_number}: #{e.message}" }
end
