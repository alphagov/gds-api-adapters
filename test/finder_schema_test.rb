require "test_helper"
require "gds_api/finder_schema"

describe GdsApi::FinderSchema do

  let(:schema) { GdsApi::FinderSchema.new(schema_hash) }

  let(:schema_hash) {
    {
      "slug" => "cma-cases",
      "name" => "Competition and Markets Authority cases",
      "document_noun" => "case",
      "facets" => [
        {
          "key" => "case_type",
          "name" => "Case type",
          "type" => "single-select",
          "include_blank" => "All case types",
          "allowed_values" => [
            {
              "label" => "CA98 and civil cartels",
              "value" => "ca98-and-civil-cartels",
            },
          ],
        },
        {
          "key" => "market_sector",
          "name" => "Market sector",
          "type" => "single-select",
          "include_blank" => false,
          "allowed_values" => [
            {
              "label" => "Aerospace",
              "value" => "aerospace",
            },
          ],
        },
      ],
    }
  }

  describe "#user_friendly_values" do
    let(:document_attrs) {
      {
        case_type: "ca98-and-civil-cartels",
        market_sector: "aerospace",
      }
    }

    let(:formatted_attrs) {
      {
        "Case type" => ["CA98 and civil cartels"],
        "Market sector" => ["Aerospace"],
      }
    }

    it "formats the given keys and values" do
      schema.user_friendly_values(document_attrs).must_equal(formatted_attrs)
    end

    describe "when a value is not found" do
      let(:document_attrs) {
        {
          market_sector: "does-not-exist"
        }
      }

      it "raises an error" do
        ->(){
          schema.user_friendly_values(document_attrs)
        }.must_raise(
          GdsApi::FinderSchema::NotFoundError,
          "market sector 'does-not-exist' not found in cma-cases schema")
      end
    end

    describe "when a value is an array of values" do
      let(:document_attrs) {
        {
          market_sector: ["aerospace"],
        }
      }

      let(:formatted_attrs) {
        {
          "Market sector" => ["Aerospace"],
        }
      }

      it "formats the given keys and values" do
        schema.user_friendly_values(document_attrs).must_equal(formatted_attrs)
      end
    end
  end
end
