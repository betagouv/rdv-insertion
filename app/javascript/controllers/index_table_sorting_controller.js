import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
      this.attachListeners();
      if (window.location.href.includes("sort_by") && window.location.href.includes("sort_direction")) {
        this.sortBy = new URL(window.location.href).searchParams.get("sort_by");
        this.sortDirection = new URL(window.location.href).searchParams.get("sort_direction");
        this.displaySortingArrow();
      }
  }

  attachListeners() {
    document.querySelectorAll(".sortable-table-header").forEach((element) => {
      element.addEventListener("click", (event) => {
        this.changeUrlParams(event);
      });
    });
  }

  changeUrlParams(event) {
    const url = new URL(window.location.href);
    this.newSortBy = event.currentTarget.id.replace("_header", "");
    // if a column is clicked for the third time, we remove the sorting
    if (this.sortDirection === undefined || this.sortBy !== this.newSortBy) {
      this.newSortDirection = "asc";
    } else if (this.sortDirection === "asc") {
      this.newSortDirection = "desc";
    } else {
      this.newSortDirection = undefined;
    }

    if (this.newSortDirection === undefined) {
      url.searchParams.delete("sort_by");
      url.searchParams.delete("sort_direction",);
    } else {
      url.searchParams.set("sort_by", this.newSortBy);
      url.searchParams.set("sort_direction", this.newSortDirection);
    }
    window.location.href = url;
  }

  displaySortingArrow() {
    const element = document.querySelector(`#${this.sortBy}_header`);
    if (element) {
      const html = ` <i class="fas fa-sort-${this.sortDirection === "asc" ? "up mt-2" : "down mb-2"}"></i>`;
      element.insertAdjacentHTML("beforeend", html);
    }
  }
}

