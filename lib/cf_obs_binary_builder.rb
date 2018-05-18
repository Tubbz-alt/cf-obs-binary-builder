#!/usr/bin/env ruby

require 'tempfile'
require 'erb'
require 'open-uri'
require 'digest'
require 'yaml'

# Define the parent module before requiring the namespaced classes
module CfObsBinaryBuilder end
require_relative 'cf_obs_binary_builder/dependency'
require_relative 'cf_obs_binary_builder/non_build_dependency'
require_relative 'cf_obs_binary_builder/bundler'
require_relative 'cf_obs_binary_builder/yarn'
require_relative 'cf_obs_binary_builder/rubygems'
require_relative 'cf_obs_binary_builder/node'
require_relative 'cf_obs_binary_builder/jruby'

module CfObsBinaryBuilder
  DEPENDENCIES = {
    "bundler" => Bundler,
    "jruby" => Jruby,
    "node" => Node,
    "rubygems" => Rubygems,
    "yarn" => Yarn
  }

  LOG_LEVELS = {
    "error" => 0,
    "warning" => 1,
    "info" => 2,
    "debug" => 3,
  }

  TMP_DIR_SUFFIX = "cf_binary_build"

  def self.run(*args)
    if args.length != 3
      abort "Wrong number of arguments, please specify: dependency, version and checksum"
    end
    abort "Dependency #{args[0]} not supported!" unless DEPENDENCIES[args[0]]

    Dir.mktmpdir(TMP_DIR_SUFFIX) do |tmpdir|
      Dir.chdir tmpdir
      DEPENDENCIES[args[0]].new(args[1],args[2]).run
    end
  end

  # This method is used to print message based on the log level set by the
  # VERBOSITY env variable. When a message is targeted for log level "info",
  # than means it will be displayed only when VERBOSITY is either info or debug.
  def self.log(message, level="info")
    user_setting = LOG_LEVELS[ENV["VERBOSITY"]] || LOG_LEVELS["info"]
    if user_setting && user_setting >= LOG_LEVELS[level]
      puts message
    end
  end
end