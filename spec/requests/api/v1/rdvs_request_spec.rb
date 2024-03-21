require "swagger_helper"

describe "Rdv API", swagger_doc: "v1/api.json" do
  with_examples

  path "api/v1/rdvs/{uuid}" do
    get "Retrieves a rdv" do
      include_context "with all existing categories"

      let!(:uuid) { SecureRandom.uuid }
      let!(:organisation) do
        create(:organisation, category_configurations: [category_configuration], motifs: [motif])
      end
      let!(:category_configuration) { create(:category_configuration, motif_category: category_rsa_orientation) }
      let!(:motif) { create(:motif, motif_category: category_rsa_orientation) }
      let!(:rdv) { create(:rdv, uuid:, organisation:, motif:) }
      let!(:agent) { create(:agent, organisations: [organisation]) }

      tags "Rdv"
      produces "application/json"
      description "Renvoie les détails du rdv"

      parameter name: :uuid, in: :path, type: :string, description: "L'uuid d'un rdv",
                example: "c5097fb5-4f79-4ef4-b723-f295d888fd98", required: true

      with_authentication

      response 200, "Renvoie le rdv" do
        schema "$ref" => "#/components/schemas/rdv_with_root"

        run_test!

        it { expect(parsed_response_body["rdv"]["id"]).to eq(rdv.id) }
      end

      it_behaves_like "an endpoint that returns 403 - forbidden" do
        let!(:agent) { create(:agent) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized"

      it_behaves_like "an endpoint that returns 404 - not found", "le rdv n'existe pas" do
        let!(:rdv) { create(:rdv, uuid: "some-other-uuid", organisation:) }
      end
    end
  end
end
