# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.swagger_root = Rails.root.join("swagger").to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under swagger_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe '...', swagger_doc: 'v2/swagger.json'
  config.swagger_docs = {
    "v1/api.json" => {
      openapi: "3.0.1",
      info: {
        title: "API RDV insertion",
        version: "v1",
        description: Rails.root.join("docs/api/description.md").read
      },
      components: {
        securitySchemes: {
          access_token: {
            type: :apiKey,
            name: "access-token",
            in: :header
          },
          uid: {
            type: :apiKey,
            name: "uid",
            in: :header
          },
          client: {
            type: :apiKey,
            name: "client",
            in: :header
          }
        },
        schemas: {
          rdv: {
            type: "object",
            properties: {
              id: { type: "integer" },
              address: { type: "string" },
              agents: {
                type: "array",
                items: { "$ref" => "#/components/schemas/agent" }
              },
              cancelled_at: { type: "string", format: "date", nullable: true },
              collectif: { type: "boolean" },
              created_by: { type: "string", enum: %w[agent user prescripteur] },
              duration_in_min: { type: "integer" },
              lieu: { "$ref" => "#/components/schemas/lieu", nullable: true },
              max_participants_count: { type: "integer", nullable: true },
              motif: { "$ref" => "#/components/schemas/motif" },
              organisation: { "$ref" => "#/components/schemas/organisation" },
              starts_at: { type: "string", format: "date" },
              status: { type: "string", enum: %w[unknown seen excused revoked noshow] },
              users: {
                type: "array",
                items: { "$ref" => "#/components/schemas/user" }
              },
              users_count: { type: "integer" },
              uuid: { type: "string" },
              rdv_solidarites_rdv_id: { type: "integer" }
            },
            required: %w[
              id starts_at duration_in_min cancelled_at address uuid created_by status
              users_count max_participants_count rdv_solidarites_rdv_id
              agents lieu motif users organisation
            ]
          },
          rdv_with_root: {
            type: "object",
            properties: {
              rdv: { "$ref" => "#/components/schemas/rdv" }
            },
            required: %w[rdv]
          },
          agents: {
            type: "object",
            properties: {
              agents: {
                type: "array",
                items: { "$ref" => "#/components/schemas/agent" }
              }
            },
            required: %w[agents]
          },
          agent: {
            type: "object",
            properties: {
              id: { type: "integer" },
              email: { type: "string" },
              first_name: { type: "string", nullable: true },
              last_name: { type: "string", nullable: true },
              rdv_solidarites_agent_id: { type: "integer" }
            },
            required: %w[id email first_name last_name rdv_solidarites_agent_id]
          },
          user_with_root: {
            type: "object",
            properties: {
              user: { "$ref" => "#/components/schemas/user" }
            },
            required: %w[user]
          },
          users: {
            type: "object",
            properties: {
              users: {
                type: "array",
                items: { "$ref" => "#/components/schemas/user" }
              }
            },
            required: %w[users]
          },
          user: {
            type: "object",
            properties: {
              id: { type: "integer" },
              address: { type: "string", nullable: true },
              affiliation_number: { type: "string", nullable: true },
              birth_date: { type: "string", format: "date", nullable: true },
              birth_name: { type: "string", nullable: true },
              created_at: { type: "string", format: "date" },
              email: { type: "string", nullable: true },
              first_name: { type: "string" },
              last_name: { type: "string" },
              phone_number: { type: "string", nullable: true },
              department_internal_id: { type: "string", nullable: true },
              rights_opening_date: { type: "string", nullable: true },
              title: { type: "string", enum: %w[monsieur madame] },
              uid: { type: "string", nullable: true },
              role: { type: "string", nullable: true, enum: %w[demandeur conjoint] },
              nir: { type: "string", nullable: true },
              france_travail_id: { type: "string", nullable: true },
              carnet_de_bord_carnet_id: { type: "string", nullable: true },
              rdv_solidarites_user_id: { type: "integer" }
            },
            required: %w[
              id uid affiliation_number role created_at department_internal_id
              first_name last_name title address phone_number email birth_date
              rights_opening_date birth_name rdv_solidarites_user_id nir france_travail_id
              carnet_de_bord_carnet_id
            ]
          },
          user_with_referents: {
            type: "object",
            properties: {
              id: { type: "integer" },
              address: { type: "string", nullable: true },
              affiliation_number: { type: "string", nullable: true },
              birth_date: { type: "string", format: "date", nullable: true },
              birth_name: { type: "string", nullable: true },
              created_at: { type: "string", format: "date" },
              email: { type: "string", nullable: true },
              first_name: { type: "string" },
              last_name: { type: "string" },
              phone_number: { type: "string", nullable: true },
              department_internal_id: { type: "string", nullable: true },
              rights_opening_date: { type: "string", nullable: true },
              title: { type: "string", enum: %w[monsieur madame] },
              uid: { type: "string", nullable: true },
              role: { type: "string", nullable: true, enum: %w[demandeur conjoint] },
              nir: { type: "string", nullable: true },
              france_travail_id: { type: "string", nullable: true },
              carnet_de_bord_carnet_id: { type: "string", nullable: true },
              rdv_solidarites_user_id: { type: "integer" },
              referents: {
                type: "array",
                items: { "$ref" => "#/components/schemas/agent" }
              }
            },
            required: %w[
              id uid affiliation_number role created_at department_internal_id
              first_name last_name title address phone_number email birth_date
              rights_opening_date birth_name rdv_solidarites_user_id nir france_travail_id
              carnet_de_bord_carnet_id
            ]
          },
          user_params: {
            type: "object",
            properties: {
              address: { type: "string", nullable: true },
              affiliation_number: { type: "string", nullable: true },
              birth_date: { type: "string", format: "date", nullable: true },
              birth_name: { type: "string", nullable: true },
              email: { type: "string", nullable: true },
              first_name: { type: "string" },
              last_name: { type: "string" },
              phone_number: { type: "string", nullable: true },
              department_internal_id: { type: "string", nullable: true },
              rights_opening_date: { type: "string", nullable: true },
              title: { type: "string", enum: %w[monsieur madame] },
              role: { type: "string", nullable: true, enum: %w[demandeur conjoint] },
              nir: { type: "string", nullable: true },
              france_travail_id: { type: "string", nullable: true },
              carnet_de_bord_carnet_id: { type: "string", nullable: true },
              invitation: {
                type: "object",
                properties: {
                  rdv_solidarites_lieu_id: { type: "string" },
                  motif_category: {
                    type: "object",
                    properties: {
                      name: { type: "string" }
                    }
                  }
                }
              },
              referents_to_add: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    email: { type: "string" }
                  }
                }
              }
            },
            required: %w[
              first_name last_name title
            ]
          },
          organisation_with_root: {
            type: "object",
            properties: {
              organisation: { "$ref" => "#/components/schemas/organisation" }
            },
            required: %w[organisation]
          },
          organisations: {
            type: "object",
            properties: {
              organisations: {
                type: "array",
                items: { "$ref" => "#/components/schemas/organisation" }
              }
            },
            required: %w[organisations]
          },
          organisation: {
            type: "object",
            properties: {
              id: { type: "integer" },
              email: { type: "string", nullable: true },
              name: { type: "string" },
              phone_number: { type: "string" },
              department_number: { type: "string" },
              rdv_solidarites_organisation_id: { type: "integer" },
              motif_categories: {
                type: "array",
                items: { "$ref" => "#/components/schemas/motif_category" }
              }
            },
            required: %w[id name email phone_number department_number rdv_solidarites_organisation_id motif_categories]
          },
          rdv_context: {
            type: "object",
            properties: {
              id: { type: "integer" },
              status: { type: "string" },
              human_status: { type: "string" },
              motif_category_id: { type: "integer" },
              participations: {
                type: "array",
                items: { "$ref" => "#/components/schemas/participation" }
              }
            }
          },
          participation: {
            type: "object",
            properties: {
              id: { type: "integer" },
              status: { type: "string" },
              created_by: { type: "string" },
              created_at: { type: "string", format: "date" },
              user: { "$ref" => "#/components/schemas/user" }
            }
          },
          invitations: {
            type: "object",
            properties: {
              invitations: {
                type: "array",
                items: { "$ref" => "#/components/schemas/invitation" }
              }
            },
            required: %w[invitations]
          },
          invitation: {
            type: "object",
            properties: {
              id: { type: "integer" },
              format: { type: "string", enum: %w[sms postal email] },
              clicked: { type: "boolean" },
              rdv_with_referents: { type: "boolean" },
              created_at: { type: "string" },
              motif_category: { "$ref" => "#/components/schemas/motif_category" }
            },
            required: %w[id format clicked rdv_with_referents created_at motif_category]
          },
          lieu: {
            type: "object",
            properties: {
              address: { type: "string" },
              name: { type: "string" },
              phone_number: { type: "string", nullable: true },
              rdv_solidarites_lieu_id: { type: "integer" }
            },
            required: %w[address name phone_number rdv_solidarites_lieu_id]
          },
          motifs: {
            type: "object",
            properties: {
              motifs: {
                type: "array",
                items: { "$ref" => "#/components/schemas/motif" }
              }
            },
            required: %w[motifs]
          },
          motif: {
            type: "object",
            properties: {
              rdv_solidarites_motif_id: { type: "integer" },
              location_type: { type: "string", enum: %w[public_office phone home] },
              name: { type: "string" },
              motif_category: { "$ref" => "#/components/schemas/motif_category" },
              collectif: { type: "boolean" },
              follow_up: { type: "boolean" }
            },
            required: %w[rdv_solidarites_motif_id name collectif location_type follow_up motif_category]
          },
          motif_category: {
            type: "object",
            properties: {
              id: { type: "integer" },
              name: { type: "string" },
              short_name: { type: "string" }
            },
            required: %w[id name short_name]
          },
          department: {
            type: "object",
            properties: {
              id: { type: "integer" },
              number: { type: "string" },
              capital: { type: "string" },
              region: { type: "string" },
              organisations: {
                type: "array",
                items: {
                  "$ref" => "#/components/schemas/organisation",
                  lieux: {
                    type: "array",
                    items: { "$ref" => "#/components/schemas/lieu" }
                  },
                  motifs: {
                    type: "array",
                    items: { "$ref" => "#/components/schemas/motif" }
                  }
                }
              }
            },
            required: %w[id number capital region organisations]
          },
          department_with_root: {
            type: "object",
            properties: {
              department: { "$ref" => "#/components/schemas/department" }
            },
            required: %w[department]
          },
          success_response: {
            type: "object",
            properties: {
              success: { type: "boolean" }
            }
          },
          error_unprocessable_entity: {
            type: "object",
            properties: {
              success: { type: "boolean" },
              errors: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    error_details: { type: "string" }
                  },
                  required: %w[error_details]
                }
              },
              required: %w[errors]
            }
          },
          error_authentication: {
            type: "object",
            properties: {
              errors: {
                type: "array",
                items: { type: "string" }
              }
            },
            required: %w[errors]
          },
          error_forbidden: {
            type: "object",
            properties: {
              errors: {
                type: "array",
                items: { type: "string" }
              }
            },
            required: %w[errors]
          },
          error_not_found: {
            type: "object",
            properties: {
              not_found: { type: "string" }
            },
            required: %w[not_found]
          }
        }
      },
      servers: [
        {
          url: "http://localhost:8000/",
          description: "Serveur de développement"
        },
        {
          url: "https://www.rdv-insertion-demo.fr",
          description: "Serveur de démo"
        },
        {
          url: "https://www.rdv-insertion.fr",
          description: "Serveur de production"
        }
      ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The swagger_docs category_configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.swagger_format = :json
end
