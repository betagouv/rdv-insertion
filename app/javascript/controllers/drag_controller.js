import { Controller } from "@hotwired/stimulus";
import Swal from "sweetalert2";
import Sortable from "sortablejs";

export default class extends Controller {
  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      onEnd: this.end.bind(this),
    });
    this.originalOrder = this.sortable.toArray();
  }

  async end() {
    const response = await fetch(this.data.get("url"), {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name=csrf-token]").content,
      },
      body: JSON.stringify({
        category_configuration_ids_and_positions: this.sortable
          .toArray()
          .map((id, index) => ({ id, position: index })),
      }),
    });

    if (!response.ok) {
      this.sortable.sort(this.originalOrder);
      Swal.fire({
        title: "Une erreur est survenue",
        text: "L'ordre de la liste ne s'est pas mis à jour, veuillez réessayer.",
        icon: "warning",
      });
    } else {
      this.originalOrder = this.sortable.toArray();
    }
  }
}
