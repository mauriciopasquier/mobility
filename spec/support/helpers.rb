module Helpers
  def stringify_keys(hash)
    result = Hash.new
    hash.each_key { |key| result[key.to_s] = hash[key] }
    result
  end

  def self.included(base)
    base.extend LazyDescribedClass
  end

  # Reset I18n.fallbacks to nil, necessary in case the default locale is
  # changed since I18n.fallbacks implicitly stores the previous default locale
  # as @@defaults.
  def reset_i18n_fallbacks
    I18n.class_variable_set(:@@fallbacks, nil)
  end

  module LazyDescribedClass
    # lazy-load described_class if it's a string
    def described_class
      klass = super
      return klass if klass

      # crawl up metadata tree looking for description that can be constantized
      this_metadata = metadata
      while this_metadata do
        candidate = this_metadata[:description_args].first
        begin
          return candidate.constantize if String === candidate
        rescue NameError, NoMethodError
        end
        this_metadata = this_metadata[:parent_example_group]
      end
    end
  end

  module Backend
    def include_backend_examples *args
      it_behaves_like "Mobility backend", *args
    end

    def include_dup_examples *args
      it_behaves_like "dupable model", *args
    end

    def include_cache_key_examples *args
      it_behaves_like "cache key", *args
    end
  end

  module ActiveRecord
    include Backend

    def include_accessor_examples *args
      it_behaves_like "model with translated attribute accessors", *args
    end

    def include_querying_examples *args
      it_behaves_like "AR Model with translated scope", *args
    end

    def include_serialization_examples *args
      it_behaves_like "AR Model with serialized translations", *args
    end

    def include_validation_examples *args
      it_behaves_like "AR Model validation", *args
    end
  end

  module Sequel
    include Backend

    def include_accessor_examples *args
      it_behaves_like "model with translated attribute accessors", *args
      it_behaves_like "Sequel model with translated attribute accessors", *args
    end

    def include_querying_examples *args
      it_behaves_like "Sequel Model with translated dataset", *args
    end

    def include_serialization_examples *args
      it_behaves_like "Sequel Model with serialized translations", *args
    end
  end

  module Generators
    def version_string
      "#{::ActiveRecord::VERSION::MAJOR}.#{::ActiveRecord::VERSION::MINOR}"
    end

    def migration_path(root, name)
      migration_root = Pathname.new(root) + "db" + "migrate"

      # Defined in railties, returns the first migration with this name or nil
      migration = Mobility::InstallGenerator.migration_exists? migration_root, name

      Pathname.new(migration.to_s)
    end
  end
end
