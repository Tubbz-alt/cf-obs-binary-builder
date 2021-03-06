class CfObsBinaryBuilder::Checksum
  SOURCE_TYPES = {
    "dep" => {
      "type" => "github_releases",
      "params" => {
        "repo" => 'golang/dep',
        "fetch_source" => true
      }
    },
    "glide" => {
      "type" => "github_releases",
      "params" => {
        "repo" => 'Masterminds/glide',
        "fetch_source" => true
      }
    },
    "godep" => {
      "type" => "github_releases",
      "params" => {
        "repo" => 'tools/godep',
        "fetch_source" => true
      }
    },
    "yarn" => {
      "type" => "github_releases",
      "params" => {
        "repo" => 'yarnpkg/yarn',
        "extension" => ".tar.gz"
      }
    },
    "rubygems" => {
      "type" => "rubygems_cli"
    },
    "bundler" => {
      "type" => "rubygems"
    },
    "composer" => {
      "type" => "github_releases",
      "params" => {
        "repo" => "composer/composer",
        "extension" => ".phar"
      }
    },
    "libgdiplus" => {
      "type" => "github_tags",
      "params" => {
        "repo" => "mono/libgdiplus",
        "tag_regex": "^[0-9]+\.[0-9]+$"
      }
    },
    "bower" => {
      "type" => "npm"
    },
    "pip" => {
      "type" => "pypi"
    },
    "pipenv" => {
      "type" => "pypi"
    },
    "setuptools" => {
      "type" => "pypi"
    },
    "pip-pop" => {
      "type" => "pypi"
    }
  }

  def self.for(name, version)
    return libffi(version) if name == "libffi"
    return libmemcache(version) if name == "libmemcache"
    return scm_dependency(version) if name == "openjdk"
    return libunwind(version) if name == "libunwind"
    return libgdiplus(version) if name == "libgdiplus"

    # There are special cases where the type does not match the dependency name.
    # See https://github.com/cloudfoundry/buildpacks-ci/blob/0b54199ecfbe98d085f4e34d224877ee415c5405/pipelines/binary-builder-new.yml#L1 for more information
    data = {
      source: {
        name: name,
        type: SOURCE_TYPES.dig(name, "type") || name
      }.merge(SOURCE_TYPES.dig(name, "params") || {} ),
      version: {
        ref: version
      }
    }.to_json
    _, output, _ = Open3.capture3("depwatcher /tmp", :stdin_data => data)
    begin
      result = JSON.parse(output.lines.last)
    rescue Exception => e
      puts "Could not parse json. Tried the last line of this output:"
      puts "---------  DEPWATCHER OUTPUT START --------------------------"
      puts output
      puts "---------  DEPWATCHER OUTPUT END ----------------------------"
      puts "Command to debug: \`echo '#{data}' | depwatcher /tmp\`"
      raise e
    end

    if result.dig("sha256") || result.dig("md5_digest") || result.dig("md5") || result.dig("sha1")
      result.dig("sha256") || result.dig("md5_digest") || result.dig("md5") || result.dig("sha1")
    elsif result.dig("pgp")
      result.dig("pgp")
    else
      raise JSON::ParserError,"Unknown checksum in depwatcher output:\n#{result}"
    end
  end

  def self.libffi(version)
    sha512list = open("https://sourceware.org/pub/libffi/sha512.sum").read
    checksum = sha512list.lines.grep(/#{Regexp.escape(version)}.tar.gz/).first&.split&.first
    raise "Could not determine checksum for libffi-#{version}.tar.gz. The checksum file content was:\n\n#{sha512list}" if !checksum

    checksum
  end

  def self.libmemcache(version)
    md5sum = URI.open("https://launchpad.net/libmemcached/1.0/#{version}/+download/libmemcached-#{version}.tar.gz/+md5").read
    checksum = md5sum.split.first
    raise "Could not determine checksum for libmemcached-#{version}.tar.gz. The checksum file content was:\n\n#{md5sum}" if !checksum

    checksum
  end

  def self.libunwind(version)
    # fix cases where the version is reported as for example 1.5 while it is 1.5.0
    if version.count('.') == 1
      version += ".0"
    end
    "http://download.savannah.nongnu.org/releases/libunwind/libunwind-#{version}.tar.gz.sig"
  end

  def self.scm_dependency(version)
    # noop - the sources are fetched from an scm repository like hg
  end

  def self.libgdiplus(version)
    case version
    when "6.0"
      "1c739e0d137b82aeecad52001a1b0d02dd403638ce792949c5228094a8945257"
    when "6.0.1"
      "169f920ec461801f7f7eb51543d679e71b2452e88932592d5aadef3a14987c23"
    when "6.0.2"
      "d605bf548affd29bd0418001ffb1bb8c1bf9962c1c37c23744abb0194a099232"
    else
      raise "Error, unknown libgdiplus version."
    end
  end
end
