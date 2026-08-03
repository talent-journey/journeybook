(() => {
  const initSortableLists = () => {
    document.querySelectorAll("[data-sortable-list]").forEach((list) => {
      if (list.dataset.sortableReady === "true") return
      list.dataset.sortableReady = "true"

      let draggedItem = null
      let changed = false

      list.addEventListener("dragstart", (event) => {
        const item = event.target.closest("[data-sortable-item]")
        if (!item || !list.contains(item)) return

        draggedItem = item
        changed = false
        item.classList.add("is-dragging")
        event.dataTransfer.effectAllowed = "move"
        event.dataTransfer.setData("text/plain", item.dataset.sortableId || "")
      })

      list.addEventListener("dragover", (event) => {
        if (!draggedItem) return

        event.preventDefault()
        event.dataTransfer.dropEffect = "move"

        const items = [ ...list.querySelectorAll(":scope > [data-sortable-item]") ]
        const target = items.find((item) => {
          if (item === draggedItem) return false
          const rect = item.getBoundingClientRect()
          return event.clientY < rect.top + rect.height / 2
        })

        if (target) {
          list.insertBefore(draggedItem, target)
        } else {
          list.appendChild(draggedItem)
        }
        changed = true
      })

      list.addEventListener("drop", (event) => event.preventDefault())

      list.addEventListener("dragend", async () => {
        if (!draggedItem) return

        draggedItem.classList.remove("is-dragging")
        const shouldSave = changed
        draggedItem = null
        changed = false
        if (!shouldSave) return

        const params = new URLSearchParams()
        list.querySelectorAll(":scope > [data-sortable-item]").forEach((item) => {
          params.append(`${list.dataset.sortableParam}[]`, item.dataset.sortableId)
        })

        try {
          await fetch(list.dataset.sortableUrl, {
            method: "PATCH",
            credentials: "same-origin",
            headers: {
              "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content || "",
              "Accept": "text/html",
              "Content-Type": "application/x-www-form-urlencoded"
            },
            body: params
          })
        } finally {
          window.location.reload()
        }
      })
    })
  }

  const initFlashes = () => {
    document.querySelectorAll("[data-flash]").forEach((flash) => {
      if (flash.dataset.dismissReady === "true") return
      flash.dataset.dismissReady = "true"
      window.setTimeout(() => flash.remove(), 2000)
    })
  }

  const init = () => {
    initSortableLists()
    initFlashes()
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init)
  } else {
    init()
  }

  document.addEventListener("turbo:load", init)
})()
