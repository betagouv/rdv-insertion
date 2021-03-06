module Notifications
  class RdvUpdated < Notifications::NotifyApplicant
    protected

    def content
      "#{@applicant.full_name},\nVotre RDV d'orientation RSA a été modifié. " +
        rdv_instructions +
        " En cas d’absence, vous risquez une suspension de votre allocation RSA. " \
        "Le département #{organisation.department_number} (#{organisation.department_name.capitalize})."
    end

    def rdv_instructions
      if rdv_presential?
        "Vous êtes attendu(e) le #{formatted_start_date} à #{formatted_start_time}" \
          " ici: #{lieu.name} - #{lieu.address}."
      else
        "Un travailleur social vous appellera le #{formatted_start_date}" \
          " à partir de #{formatted_start_time} sur ce numéro."
      end
    end
  end
end
