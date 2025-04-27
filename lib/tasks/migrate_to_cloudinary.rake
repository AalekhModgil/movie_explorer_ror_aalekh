require 'yaml'

namespace :active_storage do
  desc "Migrate Active Storage files from local disk to Cloudinary"
  task migrate_to_cloudinary: :environment do
    # Ensure Active Storage service is set to Cloudinary
    unless Rails.application.config.active_storage.service == :cloudinary
      raise "Active Storage service must be set to :cloudinary in config/environments/#{Rails.env}.rb"
    end

    # Manually load storage.yml
    storage_config_path = Rails.root.join("config/storage.yml")
    unless File.exist?(storage_config_path)
      raise "config/storage.yml not found. Please ensure the file exists."
    end

    begin
      configurations = YAML.load_file(storage_config_path, aliases: true)
      if configurations.nil? || !configurations.is_a?(Hash)
        raise "Failed to parse config/storage.yml. Please check for syntax errors."
      end
      configurations = configurations.with_indifferent_access
      Rails.application.config.active_storage.service_configurations = configurations
    rescue Psych::SyntaxError => e
      raise "Syntax error in config/storage.yml: #{e.message}"
    rescue StandardError => e
      raise "Failed to load config/storage.yml: #{e.message}"
    end

    # Debug output
    puts "Loaded configurations: #{configurations.inspect}"

    # Check for Cloudinary configuration
    unless configurations.key?(:cloudinary)
      raise "Cloudinary service configuration not found in config/storage.yml. Please ensure the :cloudinary service is defined."
    end

    cloudinary_service = configurations[:cloudinary].with_indifferent_access
    unless cloudinary_service[:cloud_name] && cloudinary_service[:api_key] && cloudinary_service[:api_secret]
      raise "Missing Cloudinary credentials in config/storage.yml. Ensure cloud_name, api_key, and api_secret are set."
    end

    # Set the Active Storage service to Cloudinary
    ActiveStorage::Blob.service = ActiveStorage::Service.configure(:cloudinary, configurations)

    # Migrate each blob from local disk to Cloudinary
    ActiveStorage::Blob.find_each do |blob|
      next unless blob.service_name == "disk" # Only migrate local files

      begin
        # Download the file locally
        file_path = Rails.root.join("tmp", blob.key)
        FileUtils.mkdir_p(File.dirname(file_path))
        File.open(file_path, "wb") do |file|
          file.write(blob.download)
        end

        # Upload to Cloudinary
        ActiveStorage::Blob.service.upload(blob.key, File.open(file_path), content_type: blob.content_type)

        # Clean up the temporary file
        File.delete(file_path) if File.exist?(file_path)

        puts "Migrated blob #{blob.key} to Cloudinary"
      rescue StandardError => e
        puts "Failed to migrate blob #{blob.key}: #{e.message}"
      end
    end

    puts "Migration to Cloudinary completed."
  end
end