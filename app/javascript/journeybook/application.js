import { Application } from "@hotwired/stimulus"
import ComponentSearchController from "journeybook/component_search_controller"

const application = Application.start()
application.register("journeybook-component-search", ComponentSearchController)
