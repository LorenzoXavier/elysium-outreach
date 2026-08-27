class ImportsController < ApplicationController
  def new
  end

  def create
    files = Array(params[:files]).reject(&:blank?)

    if files.empty?
      redirect_to new_import_path, alert: "Choose at least one CSV file to upload." and return
    end

    result = CsvImporterService.new(files).call

    notice = "Imported #{result.total} row(s) from #{files.size} file(s) -- " \
             "#{result.created} added to the pipeline, #{result.duplicates} flagged as potential duplicates."
    notice += " #{result.errors.size} row(s) had errors." if result.errors.any?

    redirect_to root_path, notice: notice
  end
end
