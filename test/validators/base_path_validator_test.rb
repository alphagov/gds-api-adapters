require "test_helper"
require "gds_api/validators/base_path_validator"

describe GdsApi::Validators::BasePathValidator do
  let(:valid_path_examples) do
    [
      nil,
      "/",
      "/government/topical-event/heat-wave-2026",
      "/government/topical-event/heat-wave-2026.csv",
      "#{'/0123456789' * 46}.jsonp",
    ]
  end

  let(:invalid_path_examples) do
    [
      "government/topical-events",
      "//",
      "//govuk",
      "/Government/topical-events",
      "/government/topical_events",
      "/government/miss-ca$h",
      "/government/files,",
      "/government/files:-more-government/",
      "/values/../../secret-stuff",
      "/govermment/news/%0D%0A",
      "/govermment/news/%0d%0a",
      "/govermment/😊",
      "/gövernment/news",
      "#{'/0123456789' * 46}x.jsonp",
      "/government/news.",
    ]
  end

  let(:invalid_path_examples_errors) do
    [
      { base_path_invalid: ["must start with a /"] },
      { base_path_invalid: ["must not include runs of . and or / characters, which could be penetration attempts"] },
      { base_path_invalid: ["must not include runs of . and or / characters, which could be penetration attempts"] },
      { base_path_invalid: ["must not include characters that are not lowercase letters, numbers, -, ., or /"] },
      { base_path_invalid: ["must not include characters that are not lowercase letters, numbers, -, ., or /"] },
      { base_path_invalid: ["must not include characters that are not lowercase letters, numbers, -, ., or /"] },
      { base_path_invalid: ["must not include characters that are not lowercase letters, numbers, -, ., or /"] },
      { base_path_invalid: ["must not include characters that are not lowercase letters, numbers, -, ., or /"] },
      { base_path_invalid: ["must not include runs of . and or / characters, which could be penetration attempts"] },
      { base_path_invalid: ["must not include characters that are not lowercase letters, numbers, -, ., or /"] },
      { base_path_invalid: ["must not include characters that are not lowercase letters, numbers, -, ., or /"] },
      { base_path_invalid: ["must not include characters that are not lowercase letters, numbers, -, ., or /"] },
      { base_path_invalid: ["must not include characters that are not lowercase letters, numbers, -, ., or /"] },
      { base_path_too_long: ["must not be longer than 512 bytes"] },
      { base_path_invalid: ["must not end with a ."] },
    ]
  end

  describe "#valid?" do
    it "returns true for valid paths" do
      valid_path_examples.each do |base_path|
        assert_equal(true, GdsApi::Validators::BasePathValidator.new(base_path).valid?, "#{base_path} should be accepted")
      end
    end

    it "returns false for valid paths" do
      invalid_path_examples.each do |base_path|
        assert_equal(false, GdsApi::Validators::BasePathValidator.new(base_path).valid?, "#{base_path} should not be accepted")
      end
    end
  end

  describe "#errors" do
    it "returns an empty hash for valid paths" do
      valid_path_examples.each do |base_path|
        assert_equal({}, GdsApi::Validators::BasePathValidator.new(base_path).errors, "#{base_path} should not return errors")
      end
    end

    it "returns appropriate errors for valid paths" do
      invalid_path_examples.each_with_index do |base_path, idx|
        assert_equal(GdsApi::Validators::BasePathValidator.new(base_path).errors, invalid_path_examples_errors[idx], "#{base_path} should include errors")
      end
    end
  end

  describe "when allow_underscores is true" do
    let(:underscored_valid_path_examples) do
      [
        nil,
        "/government/topical-events",
        "/check-benefits-financial-support/england/no/yes/sixteen_or_more_per_week/yes/yes/yes_unable_to_work/no/no/no/none_16000",
      ]
    end

    let(:still_invalid_path_examples) do
      [
        "government/topical-events",
        "//govuk",
        "/Government/topical_events",
        "government/../topical-events",
        "government/news/%0D%0A",
        "gövernment/news",
        "government/topical-events.",
        "#{'/01223456789_' * 46}x",
      ]
    end

    it "returns true for paths containing underscores" do
      underscored_valid_path_examples.each do |base_path|
        assert(
          GdsApi::Validators::BasePathValidator.new(base_path, allow_underscores: true).valid?,
          "#{base_path} should be accepted",
        )
      end
    end

    it "returns false for paths that are invalid for other reasons" do
      still_invalid_path_examples.each do |base_path|
        refute(
          GdsApi::Validators::BasePathValidator.new(base_path, allow_underscores: true).valid?,
          "#{base_path} should not be accepted",
        )
      end
    end

    it "returns errors that mention underscores are allowed" do
      errors = GdsApi::Validators::BasePathValidator.new(
        "/Government/topical_events",
        allow_underscores: true,
      ).errors

      assert_equal({ base_path_invalid: ["must not include characters that are not lowercase letters, numbers, -, ., _, or /"] }, errors)
    end
  end
end
