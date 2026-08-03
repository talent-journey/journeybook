import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "item" ]

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()

    this.itemTargets.forEach((item) => {
      item.hidden = Boolean(query) && !item.dataset.componentSearchName.toLowerCase().includes(query)
    })
  }
}
