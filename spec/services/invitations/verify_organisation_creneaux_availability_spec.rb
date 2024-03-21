describe Invitations::VerifyOrganisationCreneauxAvailability, type: :service do
  subject do
    described_class.call(organisation_id: organisation.id)
  end

  include_context "with all existing categories"

  let!(:organisation) { create(:organisation) }
  let!(:organisation_id) { organisation.id }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:follow_up_without_creneau) { create(:follow_up, motif_category: category_rsa_orientation) }
  let!(:follow_up_without_creneau_for_user_without_address) do
    create(:follow_up, motif_category: category_rsa_orientation)
  end
  let!(:follow_up2_without_creneau) { create(:follow_up, motif_category: category_rsa_orientation) }
  let!(:follow_up_with_creneau) { create(:follow_up, motif_category: category_rsa_accompagnement_sociopro) }
  let!(:follow_up_with_referent_without_creneau) do
    create(:follow_up, motif_category: category_rsa_accompagnement_social)
  end
  let!(:user1) do
    create(
      :user,
      address: "1 Rue Test 75007 Paris"
    )
  end
  let!(:user2) do
    create(
      :user,
      address: "1b Rue Test 75015 Paris"
    )
  end
  let!(:user3) do
    create(
      :user,
      address: "2 Rue Test 75020 Paris"
    )
  end
  let!(:user4) do
    create(
      :user,
      address: "3 Rue Test 75010 Paris"
    )
  end
  let!(:user_with_no_address) do
    create(
      :user,
      address: nil
    )
  end

  let!(:invitation_with_no_creneau_no_user_address) do
    create(
      :invitation,
      user: user_with_no_address,
      organisations: [organisation],
      link: "https://www.rdv-solidarites.fr/prendre_rdv?address=1RueTest&city_code=12255&departement=12&invitation_token=AIXR0X2T&latitude=44.0&longitude=2.0&motif_category_short_name=rsa_orientation&organisation_ids%5B%5D=#{organisation_id}&street_ban_id=12255_0070",
      format: "email",
      follow_up: follow_up_without_creneau_for_user_without_address
    )
  end
  let!(:invitation_with_no_creneau_no_user_address_relevant_params) do
    { :city_code => "12255",
      :address => "1RueTest",
      :latitude => "44.0",
      :longitude => "2.0",
      :departement => "12",
      :invitation_token => "AIXR0X2T",
      :motif_category_short_name => "rsa_orientation",
      :organisation_ids => [organisation_id.to_s],
      :street_ban_id => "12255_0070",
      :zip_code => nil }
  end
  let!(:invitation_with_no_creneau) do
    create(
      :invitation,
      user: user1,
      organisations: [organisation],
      link: "https://www.rdv-solidarites.fr/prendre_rdv?address=1RueTest&city_code=12255&departement=12&invitation_token=XIXR0X2T&latitude=44.0&longitude=2.0&motif_category_short_name=rsa_orientation&organisation_ids%5B%5D=#{organisation_id}&street_ban_id=12255_0070",
      format: "email",
      follow_up: follow_up_without_creneau
    )
  end
  let!(:invitation_with_no_creneau_relevant_params) do
    { :city_code => "12255",
      :address => "1RueTest",
      :latitude => "44.0",
      :longitude => "2.0",
      :departement => "12",
      :invitation_token => "XIXR0X2T",
      :motif_category_short_name => "rsa_orientation",
      :organisation_ids => [organisation_id.to_s],
      :street_ban_id => "12255_0070",
      :zip_code => "75007" }
  end
  let!(:invitation2_with_no_creneau) do
    create(
      :invitation,
      user: user2,
      organisations: [organisation],
      link: "https://www.rdv-solidarites.fr/prendre_rdv?address=1bRueTest&city_code=12255&departement=12&invitation_token=ZIXR0X2T&latitude=44.0&longitude=2.0&motif_category_short_name=rsa_orientation&organisation_ids%5B%5D=#{organisation_id}&street_ban_id=12255_0070",
      format: "email",
      follow_up: follow_up2_without_creneau
    )
  end
  let!(:invitation2_with_no_creneau_relevant_params) do
    { :city_code => "12255",
      :address => "1bRueTest",
      :latitude => "44.0",
      :longitude => "2.0",
      :departement => "12",
      :invitation_token => "ZIXR0X2T",
      :motif_category_short_name => "rsa_orientation",
      :organisation_ids => [organisation_id.to_s],
      :street_ban_id => "12255_0070",
      :zip_code => "75015" }
  end
  let!(:invitation_with_creneau) do
    create(
      :invitation,
      user: user3,
      organisations: [organisation],
      link: "https://www.rdv-solidarites.fr/prendre_rdv?address=2RueTest&city_code=12000&departement=12&invitation_token=JIXR0X2T&latitude=44.0&longitude=2.0&motif_category_short_name=rsa_accompagnement_sociopro&organisation_ids%5B%5D=#{organisation_id}&street_ban_id=12000_0000",
      format: "email",
      follow_up: follow_up_with_creneau
    )
  end
  let!(:invitation_with_creneau_relevant_params) do
    { :city_code => "12000",
      :address => "2RueTest",
      :latitude => "44.0",
      :longitude => "2.0",
      :departement => "12",
      :invitation_token => "JIXR0X2T",
      :motif_category_short_name => "rsa_accompagnement_sociopro",
      :organisation_ids => [organisation_id.to_s],
      :street_ban_id => "12000_0000",
      :zip_code => "75020" }
  end
  let!(:invitation_with_referent_without_creneau) do
    create(
      :invitation,
      user: user4,
      organisations: [organisation],
      link: "https://www.rdv-solidarites.fr/prendre_rdv?address=3RueTest&city_code=10000&departement=12&invitation_token=UIXR0X2T&latitude=44.0&longitude=2.0&motif_category_short_name=rsa_accompagnement_sociopro&organisation_ids%5B%5D=#{organisation_id}&street_ban_id=12000_0000&referent_ids%5B%5D=1",
      format: "email",
      follow_up: follow_up_with_referent_without_creneau
    )
  end
  let!(:invitation_with_referent_without_creneau_relevant_params) do
    { :city_code => "10000",
      :address => "3RueTest",
      :latitude => "44.0",
      :longitude => "2.0",
      :departement => "12",
      :invitation_token => "UIXR0X2T",
      :motif_category_short_name => "rsa_accompagnement_sociopro",
      :organisation_ids => [organisation_id.to_s],
      :street_ban_id => "12000_0000",
      :referent_ids => ["1"],
      :zip_code => "75010" }
  end

  describe "#call" do
    before do
      allow(RdvSolidaritesApi::RetrieveCreneauAvailability).to receive(:call) do |link_params:|
        case link_params
        when invitation_with_no_creneau_no_user_address_relevant_params,
          invitation_with_no_creneau_relevant_params,
          invitation2_with_no_creneau_relevant_params,
          invitation_with_referent_without_creneau_relevant_params
          OpenStruct.new(success?: true, creneau_availability: false)
        when invitation_with_creneau_relevant_params
          OpenStruct.new(success?: true, creneau_availability: true)
        else
          OpenStruct.new(success?: false)
        end
      end
    end

    it "is a success" do
      is_a_success
    end

    context "with results" do
      let!(:result) { subject }

      it "returns the right result" do
        excepted_result = [
          {
            motif_category_name: "RSA orientation",
            zip_codes: Set.new(%w[75007 75015]),
            referent_ids: Set.new([]),
            invitations_counter: 3
          },
          {
            motif_category_name: "RSA accompagnement socio-pro",
            zip_codes: Set.new(["75010"]),
            referent_ids: Set.new(["1"]),
            invitations_counter: 1
          }
        ]
        expect(result.grouped_invitation_params_by_category).to eq(excepted_result)
      end
    end
  end
end
