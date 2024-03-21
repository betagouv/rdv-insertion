require "swagger_helper"

describe "Departement API", swagger_doc: "v1/api.json" do
  with_examples
  include_context "with all existing categories"

  path "api/v1/departments/{number}" do
    get "Retrieves a department" do
      let!(:number) { "13" }
      let!(:department) do
        create(
          :department,
          name: "Bouches-du-Rhône", number: "13", capital: "Marseille",
          region: "Provence-Alpes-Côte d'Azur"
        )
      end
      let!(:organisation) do
        create(
          :organisation,
          department:, name: "Pôle Parcours", email: "pole-parcours@departement13.fr",
          category_configurations: [category_configuration]
        )
      end
      let!(:motif) { create(:motif, organisation:, motif_category: category_rsa_orientation) }
      let!(:category_configuration) { create(:category_configuration, motif_category: category_rsa_orientation) }
      let!(:agent) { create(:agent, organisations: [organisation]) }
      let!(:lieu) { create(:lieu, organisation:) }

      tags "Departement"
      produces "application/json"
      description "Renvoie les organisations, lieux et motifs du département"

      parameter name: :number, in: :path, type: :string, description: "Le numéro de département",
                example: "13", required: true

      with_authentication

      response 200, "succès" do
        schema "$ref" => "#/components/schemas/department_with_root"

        run_test! do
          expect(parsed_response_body["department"]["number"]).to eq(department.number)
        end
      end

      it_behaves_like "an endpoint that returns 403 - forbidden" do
        let!(:agent) { create(:agent) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized"

      it_behaves_like "an endpoint that returns 404 - not found", "le rdv n'existe pas" do
        let!(:department) { create(:department, number: "9999999") }
      end
    end
  end
end
