# -*- encoding : utf-8 -*-
module Lolcommits
  #
  # Methods to handle enabling and disabling of lolcommits
  #
  class Installation
    HOOK_PATH = File.join '.git', 'hooks', 'post-commit'
    HOOK_DIR = File.join '.git', 'hooks'

    #
    # IF --ENABLE, DO ENABLE
    #
    def self.do_enable
      if not File.directory?('.git')
        fatal "You don't appear to be in the base directory of a git project."
        exit 1
      end

      # its possible a hooks dir doesnt exist, so create it if so
      if not File.directory?(HOOK_DIR)
        Dir.mkdir(HOOK_DIR)
      end

      # clear away any existing lolcommits hook
      if hook_file_exists?
        remove_existing_hook! if lolcommits_hook_exists?

        # check for a good shebang line in the existing hook
        unless good_shebang?
          warn "the existing hook (at #{HOOK_PATH}) doesn't start with with a good shebang; like #!/bin/sh"
          exit 1
        end
      end

      File.open(HOOK_PATH, hook_file_exists? ? 'a' : 'w') do |f|
        f.write(hook_script(!hook_file_exists?))
      end

      FileUtils.chmod 0755, HOOK_PATH

      info 'installed lolcommit hook to:'
      info "  -> #{File.expand_path(HOOK_PATH)}"
      info '(to remove later, you can use: lolcommits --disable)'
      # we dont symlink, but rather install a small stub that calls the one from path
      # that way, as gem version changes, script updates even if new file thus breaking symlink
    end

    #
    # IF --DISABLE, DO DISABLE
    #
    def self.do_disable
      if lolcommits_hook_exists?
        remove_existing_hook!
        info "uninstalled lolcommits hook (from #{HOOK_PATH})"
      elsif File.exists?(HOOK_PATH)
        info "couldn't find an lolcommits hook (at #{HOOK_PATH})"
        if File.read(HOOK_PATH) =~ /lolcommit/
          info "warning: an older-style lolcommit hook may still exist, edit #{HOOK_PATH} to remove it manually"
        end
      else
        info "no post commit hook found (at #{HOOK_PATH}), so there is nothing to uninstall"
      end
    end

    protected

    def self.hook_script(add_shebang = true)
      shebang      = add_shebang ? "#!/bin/sh\n\n" : ''
      ruby_path    = Lolcommits::Configuration.command_which('ruby')
      hook_export  = "export PATH=\"#{ruby_path}:$PATH\"\n" if ruby_path
      capture_cmd  = 'lolcommits --capture'
      capture_args = " #{ARGV[1..-1].join(' ')}" if ARGV.length > 1

      <<-EOS
    #{shebang}### lolcommits hook (begin) ###
    #{hook_export}#{capture_cmd}#{capture_args}
    ###  lolcommits hook (end)  ###
    EOS
    end

    # does a git hook exist at all?
    def self.hook_file_exists?
      File.exists?(HOOK_PATH)
    end

    # does a git hook exist with lolcommits commands?
    def self.lolcommits_hook_exists?
      hook_file_exists? &&
        File.read(HOOK_PATH).to_s =~ /lolcommits.*\(begin\)(.*\n)*.*lolcommits.*\(end\)/
    end

    # does the git hook file have a good shebang?
    def self.good_shebang?
      File.read(HOOK_PATH).lines.first =~ /^\#\!\/bin\/.*sh/
    end

    def self.remove_existing_hook!
      hook = File.read(HOOK_PATH)
      out  = File.open(HOOK_PATH, 'w')
      skip = false

      hook.lines.each do |line|
        if !skip && (line =~ /lolcommits.*\(begin\)/)
          skip = true
        end

        out << line unless skip

        if skip && (line =~ /lolcommits.*\(end\)/)
          skip = false
        end
      end

      out.close
    end
  end
end
