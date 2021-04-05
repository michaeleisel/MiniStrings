#!/usr/bin/env ruby

require 'json'
require 'optparse'
require 'set'
require 'shellwords'

def parse_opts
  params = {}
  OptionParser.new do |opts|
    opts.on('--bundle_path PATH', String)
  end.parse!(into: params)
  params
end

def main
  opts = parse_opts
  raise "Usage: <script path> --bundle_path <path to bundle>" unless opts[:bundle_path]
  bundle_path = opts[:bundle_path]
  all_keys = Set.new
  lang_to_key_to_string = {}
  Dir["#{bundle_path}/*.lproj"].each do |dir|
    lang = File.basename(dir).delete_suffix(".lproj")
    path = "#{dir}/Localizable.strings"
    raise "Missing file for #{path}" unless File.file?(path)
    json = `plutil -convert json -o - -- #{path.shellescape}`
    key_to_string = JSON.parse(json)
    lang_to_key_to_string[lang] = key_to_string
    all_keys += key_to_string.keys
  end

  # Note that even better compression can be achieved by re-ordering the keys in a more compressible order (less change between each one)
  keys = all_keys.to_a

  out_dir = "#{bundle_path}/localization"
  system('rm', '-r', out_dir) if File.directory?(out_dir)
  system('mkdir', out_dir)
  lang_to_key_to_string.each do |lang, key_to_string|
    system('rm', "#{bundle_path}/#{lang}.lproj/Localizable.strings")
    strings = keys.map { |key| key_to_string[key] }
    IO.write("#{out_dir}/#{lang}.json", strings.to_json)
  end
  IO.write("#{out_dir}/keys.json", keys)
end

main() if __FILE__ == $0
