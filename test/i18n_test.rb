require "test_helper"
require "yaml"
require "find"

# Asserts that every t("...") call in the codebase resolves in both
# locales, and that en.yml and it.yml have the same key set. Catches:
#   - keys referenced from views/controllers but never defined
#   - keys defined in one locale but missing in the other
#   - duplicate top-level keys in YAML (silently overridden by Psych)
#   - YAML 1.1 boolean traps (`yes:` / `no:` parsed as true/false)
class I18nTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  PLURAL_KEYS = %w[zero one two few many other].freeze
  LOCALES = %w[en it].freeze
  ROOT = Rails.root

  def setup
    @defined = LOCALES.each_with_object({}) do |loc, h|
      raw = YAML.load_file(ROOT.join("config/locales/#{loc}.yml"))
      h[loc] = flatten(raw[loc])
    end
  end

  test "no duplicate top-level paths in YAML files" do
    LOCALES.each do |loc|
      dups = duplicate_paths(ROOT.join("config/locales/#{loc}.yml"))
      assert_empty dups, "Duplicate keys in #{loc}.yml (silently overridden):\n  " + dups.map { |k, ls| "#{k} at lines #{ls.join(', ')}" }.join("\n  ")
    end
  end

  test "en and it have the same key set" do
    only_en = @defined["en"] - @defined["it"]
    only_it = @defined["it"] - @defined["en"]
    msg = []
    msg << "Defined only in en (#{only_en.size}): #{only_en.sort.first(10).join(', ')}" if only_en.any?
    msg << "Defined only in it (#{only_it.size}): #{only_it.sort.first(10).join(', ')}" if only_it.any?
    assert only_en.empty? && only_it.empty?, msg.join("\n")
  end

  test "every t(...) reference resolves in both locales" do
    referenced = referenced_keys
    missing = LOCALES.each_with_object({}) do |loc, h|
      h[loc] = referenced.reject { |k| has_key?(@defined[loc], k) }
    end
    if missing.any? { |_, ks| ks.any? }
      msg = missing.map { |loc, ks| "#{loc} missing #{ks.size}: #{ks.sort.first(10).join(', ')}" }
      flunk msg.join("\n")
    end
  end

  private

  def flatten(hash, prefix = nil, out = Set.new)
    hash.each do |k, v|
      full = [prefix, k].compact.join(".")
      v.is_a?(Hash) ? flatten(v, full, out) : out << full
    end
    out
  end

  def has_key?(set, key)
    set.include?(key) || PLURAL_KEYS.any? { |p| set.include?("#{key}.#{p}") }
  end

  def view_scope(path)
    rel = path.sub(%r{^.*/app/views/}, "")
    rel.sub(/\.[a-z]+\.erb$/, "").sub(/\.erb$/, "").gsub("/_", "/").tr("/", ".")
  end

  def referenced_keys
    out = Set.new
    static_re = /\bt[\s(]+(['"])([a-z][a-z0-9_.]*)\1/
    lazy_re   = /\bt[\s(]+(['"])(\.[a-z0-9_.]+)\1/
    %w[app/views app/controllers app/mailers app/helpers app/models].each do |dir|
      Find.find(ROOT.join(dir).to_s) do |path|
        next unless File.file?(path) && path =~ /\.(rb|erb)$/
        body = File.read(path)
        body.scan(static_re) { |_, key| out << key }
        if path.include?("/app/views/")
          scope = view_scope(path)
          body.scan(lazy_re) { |_, key| out << scope + key }
        end
      end
    end
    out
  end

  # Walk the YAML file textually and detect duplicate paths.
  # Psych silently picks one when paths collide; this catches that bug.
  def duplicate_paths(path)
    stack = []
    seen = Hash.new { |h, k| h[k] = [] }
    File.readlines(path).each_with_index do |line, idx|
      next if line.strip.start_with?("#") || line.strip.empty?
      next unless line =~ /^(\s*)([a-zA-Z_][\w\.]*|"[^"]+"):\s*(.*)$/
      indent, key, value = $1.length, $2.tr('"', ""), $3
      stack.pop while stack.last && stack.last[0] >= indent
      full = stack.map { |_, k| k }.push(key).join(".")
      seen[full] << idx + 1
      stack << [indent, key] if value.empty?
    end
    seen.select { |_, ls| ls.size > 1 }
  end
end
