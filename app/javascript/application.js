// Entry point for the build script in your package.json

import '@hotwired/turbo-rails'
import * as ActiveStorage from "@rails/activestorage"
import * as bootstrap from 'bootstrap'
import './bootstrap-tabs'
import './channels'
import './controllers'
import './datatables'
import './multiselect'

bootstrap

ActiveStorage.start()

require("trix")
require("@rails/actiontext")
