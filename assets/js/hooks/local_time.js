const LocalTime = {
  mounted() {
    this.updateTime()
  },
  updated() {
    this.updateTime()
  },
  updateTime() {
    const dt = this.el.dataset.date
    const tm = this.el.dataset.time
    if (!dt) return

    // Construct ISO string
    // Assuming date is YYYY-MM-DD and time is HH:MM:SS
    // Appending 'Z' to treat it as UTC if that's how it's stored.
    // Ecto :utc_datetime is stored as UTC.
    // But here we have separate date and time fields.
    // If they are separate, we combine them.

    let isoString
    if (tm) {
      isoString = `${dt}T${tm}Z`
    } else {
      isoString = dt // Just date
    }

    const date = new Date(isoString)

    if (isNaN(date.getTime())) return

    const options = {
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      timeZoneName: "short",
    }

    if (!tm) {
      delete options.hour
      delete options.minute
      delete options.timeZoneName
    }

    this.el.innerText = date.toLocaleString(undefined, options)
    this.el.classList.remove("invisible")
  },

  destroyed() {
    // No cleanup needed - this hook only updates DOM on mount/update
  },
}

export default LocalTime
