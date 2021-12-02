class DepartmentSelector {
  constructor() {
    this.selectElt = document.querySelector(".js-department-selector");
    if (this.selectElt === null) return;

    this.setIntialValue();
    this.attachListener();
  }

  setIntialValue() {
    const url = new URL(window.location.href);
    const selectedDepartment = url.searchParams.get("department");
    if (selectedDepartment) {
      this.selectElt.value = selectedDepartment;
    }
  }

  attachListener() {
    this.selectElt.addEventListener("change", (event) => {
      this.refreshQuery(event.target.value);
    });
  }

  refreshQuery(selectedDepartment) {
    if (selectedDepartment && selectedDepartment !== "0") {
      const url = new URL(window.location.href);
      url.searchParams.set("department", selectedDepartment);
      window.location.href = url;
    } else {
      const url = new URL(window.location.href);
      url.searchParams.delete("department");
      window.location.href = url;
    }
  }
}

export default DepartmentSelector;
