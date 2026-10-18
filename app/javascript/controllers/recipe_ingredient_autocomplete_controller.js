import { Controller } from "@hotwired/stimulus"

// Suggests units, ingredient names and diets while an ingredient is typed into
// the Markdown recipe text, i.e. between an opening `**` and the caret:
//
//   **500 g Mandeln (+vegan,-nussfrei)**
//     |     |   |         `- diets
//     |     |   `- ingredient name
//     |     `- unit
//     `- quantity
//
// The patterns mirror INGREDIENT_REGEXP in app/models/recipe.rb.
const QUANTITY = "\\d+(?:,\\d+)?"
const UNIT_STEP = new RegExp(`^${QUANTITY} (\\S*)$`)
const NAME_STEP = new RegExp(`^${QUANTITY} (\\S+) ([^()]*)$`)
const DIET_STEP = new RegExp(`^${QUANTITY} \\S+ [^()]*\\(([^()]*)$`)
const QUANTITY_STEP = /^\d*(?:,\d*)?$/
const MAX_SUGGESTIONS = 8

// Connects to data-controller="recipe-ingredient-autocomplete"
export default class extends Controller {
  static targets = ["input"]
  static values = { units: Array, acceptedUnits: Array, ingredients: Array, diets: Array }

  connect() {
    this.menu = document.createElement("ul")
    this.menu.id = `${this.inputTarget.id || "recipe-content"}-suggestions`
    this.menu.className = "dropdown-menu shadow-sm recipe-ingredient-suggestions"
    this.menu.setAttribute("role", "listbox")
    this.menu.hidden = true
    this.menu.addEventListener("mousedown", (event) => event.preventDefault())
    this.menu.addEventListener("click", this.onMenuClick)
    this.element.appendChild(this.menu)

    const input = this.inputTarget
    input.setAttribute("aria-autocomplete", "list")
    input.setAttribute("aria-controls", this.menu.id)
    input.setAttribute("aria-expanded", "false")
    input.addEventListener("input", this.update)
    input.addEventListener("click", this.update)
    input.addEventListener("keydown", this.onKeydown)
    input.addEventListener("keyup", this.onKeyup)
    input.addEventListener("blur", this.close)
    input.addEventListener("scroll", this.close)
  }

  disconnect() {
    const input = this.inputTarget
    input.removeEventListener("input", this.update)
    input.removeEventListener("click", this.update)
    input.removeEventListener("keydown", this.onKeydown)
    input.removeEventListener("keyup", this.onKeyup)
    input.removeEventListener("blur", this.close)
    input.removeEventListener("scroll", this.close)
    this.menu.remove()
  }

  update = () => {
    const context = this.currentContext()
    if (!context) this.dismissedSpanStart = null
    if (!context || context.spanStart === this.dismissedSpanStart) return this.close()

    this.ingredientContext = context
    this.items = this.itemsFor(context)
    if (this.items.length === 0) return this.close()

    this.activeIndex = this.items.findIndex((item) => item.insert !== undefined)
    this.render()
  }

  close = () => {
    if (this.menu.hidden) return

    this.menu.hidden = true
    this.inputTarget.setAttribute("aria-expanded", "false")
    this.inputTarget.removeAttribute("aria-activedescendant")
  }

  onKeydown = (event) => {
    if (this.menu.hidden) return

    switch (event.key) {
      case "ArrowDown":
      case "ArrowUp":
        if (this.activeIndex < 0) return
        event.preventDefault()
        this.moveActive(event.key === "ArrowDown" ? 1 : -1)
        break
      case "Enter":
      case "Tab":
        if (this.activeIndex < 0) return
        event.preventDefault()
        this.select(this.items[this.activeIndex])
        break
      case "Escape":
        event.preventDefault()
        this.dismissedSpanStart = this.ingredientContext.spanStart
        this.close()
        break
    }
  }

  // Caret moves without typing (Home/End/arrows while the menu is closed).
  onKeyup = (event) => {
    if (["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key) ||
        (this.menu.hidden && ["ArrowUp", "ArrowDown"].includes(event.key))) {
      this.update()
    }
  }

  onMenuClick = (event) => {
    const option = event.target.closest("[data-index]")
    if (option) this.select(this.items[Number(option.dataset.index)])
  }

  // Works out which part of an ingredient the caret is in, or null when it is
  // not inside an unclosed `**` span on the current line.
  currentContext() {
    const input = this.inputTarget
    const caret = input.selectionStart
    if (caret !== input.selectionEnd) return null

    const before = input.value.slice(0, caret)
    const lineStart = before.lastIndexOf("\n") + 1
    const markers = before.slice(lineStart).split("**").length - 1
    if (markers % 2 === 0) return null

    const spanStart = before.lastIndexOf("**") + 2
    const fragment = before.slice(spanStart)
    // The user is typing the closing `**`.
    if (fragment.endsWith("*")) return null

    const after = input.value.slice(caret)
    let match

    if ((match = fragment.match(DIET_STEP))) {
      const token = match[1].split(",").pop().trimStart()
      return { step: "diet", spanStart, caret, query: token, after }
    }
    if ((match = fragment.match(NAME_STEP))) {
      return { step: "name", spanStart, caret, unit: match[1], query: match[2], after }
    }
    if ((match = fragment.match(UNIT_STEP))) {
      return { step: "unit", spanStart, caret, query: match[1], after }
    }
    return { step: QUANTITY_STEP.test(fragment) ? "quantity" : "invalid", spanStart, caret, after }
  }

  itemsFor(context) {
    switch (context.step) {
      case "quantity":
        return [hint("Menge eingeben, z. B. „500 g Mehl“")]
      case "invalid":
        return [warning("Zutaten beginnen mit Menge und Einheit, z. B. „500 g Mehl“")]
      case "unit":
        return this.unitItems(context)
      case "name":
        return this.nameItems(context)
      case "diet":
        return this.dietItems(context)
    }
  }

  unitItems({ query, after }) {
    const tail = after.match(/^[^\s*]*/)[0]
    const space = after.slice(tail.length).startsWith(" ") ? "" : " "
    const items = rank(this.unitsValue, query).map((unit) => ({
      label: unit,
      insert: unit + space,
      replace: /^[^\s*]*/
    }))
    if (items.length > 0) return items
    return [warning(`„${query}“ ist keine erlaubte Einheit`)]
  }

  nameItems({ unit, query, after }) {
    const warnings = this.acceptedUnitsValue.includes(unit) ? [] : [warning(`„${unit}“ ist keine erlaubte Einheit`)]
    const name = query.trim()
    if (name === "") return [...warnings, hint("Zutat eingeben")]

    const rest = after.slice(after.match(/^[^*()\n]*/)[0].trimEnd().length)
    const closing = /^\s*(\(|\*\*)/.test(rest) ? "" : "**"
    const items = rank(this.ingredientsValue, name).map((ingredient) => ({
      label: ingredient,
      insert: ingredient + closing,
      replace: /^[^*()\n]*/,
      trimEnd: true
    }))
    if (!this.ingredientsValue.includes(name)) {
      items.push(hint(`„${name}“ wird als neue Zutat angelegt`))
    }
    return [...warnings, ...items]
  }

  dietItems({ query }) {
    const sign = query.match(/^[+-]/)?.[0]
    const name = sign ? query.slice(1) : query
    const signs = sign ? [sign] : ["+", "-"]
    const items = rank(this.dietsValue, name).flatMap((diet) =>
      signs.map((s) => ({ label: `${s}${diet}`, insert: `${s}${diet}`, replace: /^[^,()*\n]*/ }))
    ).slice(0, MAX_SUGGESTIONS)
    if (items.length > 0) return items
    if (name === "") return [hint("Diät mit + (geeignet) oder - (ungeeignet) eingeben")]
    // Recipe#parse_diets ignores diets without a sign.
    if (!sign) return [warning(`„${name}“ mit + (geeignet) oder - (ungeeignet) kennzeichnen`)]
    return [hint(`Diät „${name}“ wird neu angelegt`)]
  }

  select(item) {
    if (!item || item.insert === undefined) return

    const { caret, after, query } = this.ingredientContext
    let tail = after.match(item.replace)[0]
    if (item.trimEnd) tail = tail.trimEnd()

    insertText(this.inputTarget, caret - query.length, caret + tail.length, item.insert)
    this.update()
  }

  moveActive(step) {
    const selectable = this.items.map((item, index) => [item, index]).filter(([item]) => item.insert !== undefined)
    const position = selectable.findIndex(([, index]) => index === this.activeIndex)
    this.activeIndex = selectable[(position + step + selectable.length) % selectable.length][1]
    this.render()
  }

  render() {
    this.menu.replaceChildren(...this.items.map((item, index) => {
      const li = document.createElement("li")
      const option = document.createElement(item.insert === undefined ? "span" : "button")
      option.textContent = item.label
      option.id = `${this.menu.id}-${index}`
      if (item.insert === undefined) {
        option.className = `dropdown-item-text small ${item.warning ? "text-danger" : "text-body-secondary"}`
      } else {
        option.type = "button"
        option.tabIndex = -1
        option.className = `dropdown-item${index === this.activeIndex ? " active" : ""}`
        option.dataset.index = index
        option.setAttribute("role", "option")
        option.setAttribute("aria-selected", index === this.activeIndex)
      }
      li.appendChild(option)
      return li
    }))

    const input = this.inputTarget
    this.menu.hidden = false
    this.menu.classList.add("show")
    const { top, left, height } = caretCoordinates(input, this.ingredientContext.caret)
    const maxLeft = input.offsetLeft + input.clientWidth - this.menu.offsetWidth
    this.menu.style.position = "absolute"
    this.menu.style.top = `${input.offsetTop + top - input.scrollTop + height}px`
    this.menu.style.left = `${Math.max(input.offsetLeft, Math.min(input.offsetLeft + left - input.scrollLeft, maxLeft))}px`

    input.setAttribute("aria-expanded", "true")
    if (this.activeIndex >= 0) {
      input.setAttribute("aria-activedescendant", `${this.menu.id}-${this.activeIndex}`)
    } else {
      input.removeAttribute("aria-activedescendant")
    }
  }
}

function hint(label) {
  return { label }
}

function warning(label) {
  return { label, warning: true }
}

// Case-insensitive matches: prefix matches first, then word starts, then any substring.
function rank(candidates, query) {
  const needle = query.toLocaleLowerCase("de")
  const scored = []
  for (const candidate of candidates) {
    const haystack = candidate.toLocaleLowerCase("de")
    const index = haystack.indexOf(needle)
    if (index < 0) continue
    const score = index === 0 ? 0 : /[\s,(-]/.test(haystack[index - 1]) ? 1 : 2
    scored.push([score, candidate])
  }
  return scored
    .sort((a, b) => a[0] - b[0] || a[1].localeCompare(b[1], "de"))
    .slice(0, MAX_SUGGESTIONS)
    .map(([, candidate]) => candidate)
}

// Replaces start...end with text while keeping the browser's undo history.
function insertText(input, start, end, text) {
  input.focus()
  input.setSelectionRange(start, end)
  if (!document.execCommand("insertText", false, text)) {
    input.setRangeText(text, start, end, "end")
    input.dispatchEvent(new Event("input", { bubbles: true }))
  }
}

const MIRRORED_PROPERTIES = [
  "boxSizing", "width", "borderTopWidth", "borderRightWidth", "borderBottomWidth", "borderLeftWidth",
  "paddingTop", "paddingRight", "paddingBottom", "paddingLeft", "fontStyle", "fontVariant", "fontWeight",
  "fontStretch", "fontSize", "lineHeight", "fontFamily", "textAlign", "textTransform", "textIndent",
  "letterSpacing", "wordSpacing", "tabSize"
]

// Pixel position of the caret inside a textarea, measured on an off-screen copy.
function caretCoordinates(input, position) {
  const mirror = document.createElement("div")
  const style = getComputedStyle(input)
  for (const property of MIRRORED_PROPERTIES) mirror.style[property] = style[property]
  Object.assign(mirror.style, {
    position: "absolute", visibility: "hidden", top: "0", left: "-9999px",
    whiteSpace: "pre-wrap", overflowWrap: "break-word", overflow: "hidden"
  })
  mirror.textContent = input.value.slice(0, position)
  const marker = document.createElement("span")
  marker.textContent = input.value.slice(position) || "."
  mirror.appendChild(marker)
  document.body.appendChild(mirror)

  const coordinates = {
    top: marker.offsetTop,
    left: marker.offsetLeft,
    height: parseFloat(style.lineHeight) || parseFloat(style.fontSize) * 1.5
  }
  mirror.remove()
  return coordinates
}
