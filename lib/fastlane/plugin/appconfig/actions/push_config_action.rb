require 'fastlane/action'
require 'fileutils'
require 'git'
require 'match'
require 'terminal-table'
require_relative '../helper/appconfig_helper'

module Fastlane
  module Actions
    class PushConfigAction < Action

      @@tmp_dir = "#{Dir.pwd}/.tmp"

      def self.run(params)
        remove_tmp_dir_if_exists

        bundle_id               = params[:bundle_id]
        bundled_files           = params[:bundled_files]
        bundled_encrypted_files = params[:bundled_encrypted_files]
        common_files            = params[:common_files]
        common_encrypted_files  = params[:common_encrypted_files]
        git_repo                = params[:git_repo]
        git_ref                 = params[:git_ref]
        passphrase              = params[:passphrase]

        title = 'Push Config'
        headings = ['Parameter', 'Value']
        rows = []
        rows << ['bundle_id', bundle_id]
        rows << ['git_repo', git_repo]
        rows << ['git_ref', git_ref]
        table = Terminal::Table.new :title => title, :headings => headings, :rows => rows
        puts("\n" + table.to_s + "\n")

        separator = "\n\t- "
        UI.message "bundled_files:#{separator}#{bundled_files.join(separator)}" unless bundled_files.empty?
        UI.message "bundled_encrypted_files:#{separator}#{bundled_encrypted_files.join(separator)}" unless bundled_encrypted_files.empty?
        UI.message "common_files:#{separator}#{common_files.join(separator)}" unless common_files.empty?
        UI.message "common_encrypted_files:#{separator}#{common_encrypted_files.join(separator)}" unless common_encrypted_files.empty?

        # Clone the repo
        git_name = git_repo.split('/').last
        git = Git.clone(git_repo, git_name, path: @@tmp_dir)
        git.checkout(git_ref)

        # Bundled files
        bundled_dst = "#{@@tmp_dir}/#{git_name}/#{bundle_id}"
        copy_files(bundled_files, bundled_dst)
        copy_and_encrypt_files(bundled_encrypted_files, bundled_dst, passphrase)

        # Common files
        common_dst = "#{@@tmp_dir}/#{git_name}/common"
        copy_files(common_files, common_dst)
        copy_and_encrypt_files(common_encrypted_files, common_dst, passphrase)

        # Commit the changes
        git.add
        git.commit "[AppConfig] Updating files for #{bundle_id}"
        git.push(git.remote('origin'), git.branch(git_ref))
        remove_tmp_dir_if_exists
      end

      def self.copy_files(files, destination)
        files.each do |file|
          dst = "#{destination}/#{file}"
          src = "#{Dir.pwd}/#{file}"
          FileUtils.mkdir_p(File.dirname(dst))
          FileUtils.cp(src, dst)
        end
      end

      def self.copy_and_encrypt_files(files, destination, passphrase)
        match = Match::Encrypt.new
        files.each do |file|
          dst = "#{destination}/#{file}"
          src = "#{Dir.pwd}/#{file}"
          FileUtils.mkdir_p(File.dirname(dst))
          FileUtils.cp(src, dst)
          match.appconfig_encrypt(path: dst, password: passphrase)
        end
      end

      def self.remove_tmp_dir_if_exists
        FileUtils.remove_dir(@@tmp_dir) if Dir.exist?(@@tmp_dir)
      end

      def self.description
        'This action will push common, bundled, and encrypt them if necessary, to a configuration repo'
      end

      def self.authors
        ['Ben Sarrazin']
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        self.description
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :bundle_id,
            env_name: 'APPCONFIG_BUNDLE_ID',
            description: 'The bundle id of the configuration',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :bundled_files,
            description: 'The list of file to store in a bundle',
            optional: true,
            default_value: [],
            type: Array
          ),
          FastlaneCore::ConfigItem.new(
            key: :bundled_encrypted_files,
            description: 'The list of encrypted files to store in a bundle',
            optional: true,
            default_value: [],
            type: Array
          ),
          FastlaneCore::ConfigItem.new(
            key: :common_files,
            description: 'The list of files to store in the common folder',
            optional: true,
            default_value: [],
            type: Array
          ),
          FastlaneCore::ConfigItem.new(
            key: :common_encrypted_files,
            description: 'The list of encrypted files to store in the common folder',
            optional: true,
            default_value: [],
            type: Array
          ),
          FastlaneCore::ConfigItem.new(
            key: :git_repo,
            env_name: 'APPCONFIG_GIT_REPO',
            description: 'The git repository where the configurations are stored',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :git_ref,
            env_name: 'APPCONFIG_GIT_REF',
            description: 'The git reference (tag, branch or commit) of the configuration',
            optional: true,
            default_value: 'master',
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :passphrase,
            description: 'The passphrase used to encrypt the files',
            optional: false,
            type: String
          )
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
