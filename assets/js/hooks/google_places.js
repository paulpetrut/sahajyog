/**
 * Google Places Autocomplete Hook - Using Autocomplete API
 *
 * Uses the Places API Autocomplete endpoint for simple city/country suggestions
 */

const GooglePlaces = {
  mounted() {
    const apiKey = this.el.dataset.apiKey
    const searchType = this.el.dataset.searchType || "city"

    if (!apiKey) {
      return
    }

    this.apiKey = apiKey
    this.searchType = searchType
    this.debounceTimer = null
    this.suggestionsContainer = null
    this.sessionToken = this.generateSessionToken()
    this.lastValue = this.el.value.trim() // Store initial value

    // Find the country field if this is a city field
    if (this.searchType === "city") {
      this.countryField = document.getElementById("event_country")
    }

    this.createSuggestionsContainer()
    this.setupInputListener()
  },

  generateSessionToken() {
    // Generate a random session token for billing optimization
    return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function (c) {
      const r = (Math.random() * 16) | 0
      const v = c === "x" ? r : (r & 0x3) | 0x8
      return v.toString(16)
    })
  },

  createSuggestionsContainer() {
    this.suggestionsContainer = document.createElement("div")
    this.suggestionsContainer.id = `places-suggestions-${this.el.id}`
    this.suggestionsContainer.className =
      "fixed z-[9999] bg-base-100 border border-base-content/20 rounded-lg shadow-lg max-h-60 overflow-y-auto hidden"

    document.body.appendChild(this.suggestionsContainer)
    this.positionSuggestions()
  },

  positionSuggestions() {
    if (!this.suggestionsContainer) return

    const rect = this.el.getBoundingClientRect()
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop
    const scrollLeft = window.pageXOffset || document.documentElement.scrollLeft

    // Position directly below the input
    this.suggestionsContainer.style.top = `${rect.bottom + scrollTop + 4}px`
    this.suggestionsContainer.style.left = `${rect.left + scrollLeft}px`
    this.suggestionsContainer.style.width = `${rect.width}px`
  },

  setupInputListener() {
    this.selectedIndex = -1 // Track selected suggestion index

    this.inputHandler = (e) => {
      const query = e.target.value.trim()

      // Store the current value
      this.lastValue = query

      // Require more characters for country search (3+) to get better results
      const minLength = this.searchType === "country" ? 3 : 2

      if (query.length < minLength) {
        this.hideSuggestions()
        return
      }

      clearTimeout(this.debounceTimer)
      this.debounceTimer = setTimeout(() => {
        this.searchPlaces(query)
      }, 300)
    }

    this.el.addEventListener("input", this.inputHandler)

    // Keyboard navigation
    this.keydownHandler = (e) => {
      const isOpen = !this.suggestionsContainer.classList.contains("hidden")
      if (!isOpen) return

      const items = this.suggestionsContainer.querySelectorAll(".suggestion-item")
      if (items.length === 0) return

      switch (e.key) {
        case "ArrowDown":
          e.preventDefault()
          this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1)
          this.highlightItem(items)
          break

        case "ArrowUp":
          e.preventDefault()
          this.selectedIndex = Math.max(this.selectedIndex - 1, -1)
          this.highlightItem(items)
          break

        case "Enter":
          e.preventDefault()
          if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
            items[this.selectedIndex].click()
          }
          break

        case "Escape":
          e.preventDefault()
          this.hideSuggestions()
          break
      }
    }

    this.el.addEventListener("keydown", this.keydownHandler)

    this.clickHandler = (e) => {
      if (!this.el.contains(e.target) && !this.suggestionsContainer.contains(e.target)) {
        this.hideSuggestions()
      }
    }
    document.addEventListener("click", this.clickHandler)

    // Close dropdown on scroll for better UX
    this.scrollHandler = () => {
      if (!this.suggestionsContainer.classList.contains("hidden")) {
        this.hideSuggestions()
      }
    }
    window.addEventListener("scroll", this.scrollHandler, true)

    // Reposition on window resize
    this.resizeHandler = () => {
      if (!this.suggestionsContainer.classList.contains("hidden")) {
        this.positionSuggestions()
      }
    }
    window.addEventListener("resize", this.resizeHandler)
  },

  highlightItem(items) {
    items.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.classList.add("bg-base-200")
        item.scrollIntoView({ block: "nearest", behavior: "smooth" })
      } else {
        item.classList.remove("bg-base-200")
      }
    })
  },

  async searchPlaces(query) {
    try {
      // Use Autocomplete API endpoint
      const url = `https://places.googleapis.com/v1/places:autocomplete`

      // Set types based on search type
      const types = this.searchType === "country" ? ["country"] : ["(cities)"]

      const requestBody = {
        input: query,
        includedPrimaryTypes: types,
        sessionToken: this.sessionToken,
      }

      // If searching for cities and country is selected, restrict to that country
      if (this.searchType === "city" && this.countryField) {
        const selectedCountry = this.countryField.value.trim()
        if (selectedCountry) {
          requestBody.includedRegionCodes = [this.getCountryCode(selectedCountry)]
        }
      }

      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": this.apiKey,
        },
        body: JSON.stringify(requestBody),
      })

      if (!response.ok) {
        return
      }

      const data = await response.json()

      if (data.suggestions && data.suggestions.length > 0) {
        this.showSuggestions(data.suggestions)
      } else {
        this.hideSuggestions()
      }
    } catch (error) {
      // Failed to search places
    }
  },

  getCountryCode(countryName) {
    // Map common country names to ISO 3166-1 alpha-2 codes
    const countryMap = {
      spain: "ES",
      france: "FR",
      italy: "IT",
      germany: "DE",
      "united kingdom": "GB",
      "united states": "US",
      uk: "GB",
      england: "GB",
      scotland: "GB",
      wales: "GB",
      "northern ireland": "GB",
      britain: "GB",
      "great britain": "GB",
      usa: "US",
      america: "US",
      canada: "CA",
      australia: "AU",
      india: "IN",
      china: "CN",
      japan: "JP",
      brazil: "BR",
      mexico: "MX",
      russia: "RU",
      "south africa": "ZA",
      argentina: "AR",
      chile: "CL",
      colombia: "CO",
      peru: "PE",
      venezuela: "VE",
      portugal: "PT",
      netherlands: "NL",
      holland: "NL",
      belgium: "BE",
      switzerland: "CH",
      austria: "AT",
      sweden: "SE",
      norway: "NO",
      denmark: "DK",
      finland: "FI",
      poland: "PL",
      greece: "GR",
      turkey: "TR",
      egypt: "EG",
      morocco: "MA",
      nigeria: "NG",
      kenya: "KE",
      "south korea": "KR",
      korea: "KR",
      thailand: "TH",
      vietnam: "VN",
      indonesia: "ID",
      malaysia: "MY",
      singapore: "SG",
      philippines: "PH",
      "new zealand": "NZ",
      ireland: "IE",
      romania: "RO",
      ukraine: "UA",
      czechia: "CZ",
      "czech republic": "CZ",
      hungary: "HU",
      bulgaria: "BG",
      croatia: "HR",
      serbia: "RS",
      slovakia: "SK",
      slovenia: "SI",
    }

    const normalized = countryName.toLowerCase().trim()
    return countryMap[normalized] || ""
  },

  showSuggestions(suggestions) {
    this.positionSuggestions()
    this.suggestionsContainer.innerHTML = ""
    this.selectedIndex = -1 // Reset selection

    suggestions.forEach((suggestion, index) => {
      const placePrediction = suggestion.placePrediction
      if (!placePrediction) return

      const item = document.createElement("div")
      item.className =
        "suggestion-item px-4 py-2 hover:bg-base-200 cursor-pointer text-base-content border-b border-base-content/10 last:border-b-0"
      item.dataset.index = index

      const mainText = placePrediction.text?.text || ""
      const secondaryText = placePrediction.structuredFormat?.secondaryText?.text || ""

      item.innerHTML = `
        <div class="font-medium">${mainText}</div>
        ${secondaryText ? `<div class="text-sm text-base-content/60">${secondaryText}</div>` : ""}
      `

      item.addEventListener("click", () => {
        this.selectPlace(placePrediction)
      })

      this.suggestionsContainer.appendChild(item)
    })

    this.suggestionsContainer.classList.remove("hidden")
  },

  hideSuggestions() {
    if (this.suggestionsContainer) {
      this.suggestionsContainer.classList.add("hidden")
      this.selectedIndex = -1
    }
  },

  async selectPlace(placePrediction) {
    const placeId = placePrediction.placeId
    const mainText = placePrediction.text?.text || ""

    // Update input immediately with main text
    this.el.value = mainText
    this.hideSuggestions()

    // Fetch place details to get full address components
    try {
      const url = `https://places.googleapis.com/v1/places/${placeId}`

      const response = await fetch(url, {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": this.apiKey,
          "X-Goog-FieldMask": "addressComponents",
        },
      })

      if (!response.ok) {
        // Failed to fetch place details
        this.sendToLiveView(mainText, "")
        return
      }

      const placeDetails = await response.json()

      // Extract city and country from address components
      let city = ""
      let country = ""

      if (placeDetails.addressComponents) {
        placeDetails.addressComponents.forEach((component) => {
          const types = component.types || []

          if (types.includes("locality")) {
            city = component.longText || component.shortText || ""
          } else if (types.includes("administrative_area_level_1") && !city) {
            city = component.longText || component.shortText || ""
          }

          if (types.includes("country")) {
            country = component.longText || component.shortText || ""
          }
        })
      }

      // For country search, use main text as country
      if (this.searchType === "country") {
        country = mainText
        city = ""
      } else if (!city) {
        // Fallback for city search
        city = mainText
      }

      this.sendToLiveView(city, country)
    } catch (error) {
      // Error fetching place details - send what we have
      if (this.searchType === "country") {
        this.sendToLiveView("", mainText)
      } else {
        this.sendToLiveView(mainText, "")
      }
    }
  },

  sendToLiveView(city, country) {
    this.pushEvent("place_selected", {
      city: city,
      country: country,
      lat: null,
      lng: null,
    })
  },

  destroyed() {
    if (this.inputHandler) {
      this.el.removeEventListener("input", this.inputHandler)
    }
    if (this.keydownHandler) {
      this.el.removeEventListener("keydown", this.keydownHandler)
    }
    if (this.clickHandler) {
      document.removeEventListener("click", this.clickHandler)
    }
    if (this.scrollHandler) {
      window.removeEventListener("scroll", this.scrollHandler, true)
    }
    if (this.resizeHandler) {
      window.removeEventListener("resize", this.resizeHandler)
    }
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }
    if (this.suggestionsContainer && this.suggestionsContainer.parentElement) {
      this.suggestionsContainer.remove()
    }
  },
}

export default GooglePlaces
