import { ajax } from "discourse/lib/ajax";
import { withPluginApi } from "discourse/lib/plugin-api";

let currentTooltip = null;
let fetchCache = new Map();

function initializeScryfallTooltips(api) {
  api.decorateCookedElement(
    (element) => {
      const links = element.querySelectorAll("a.scryfall-card-link");

      links.forEach((link) => {
        // Prevent duplicate event listeners
        if (link.dataset.tooltipInitialized) {
          return;
        }
        link.dataset.tooltipInitialized = "true";

        let hoverTimeout = null;

        link.addEventListener("mouseenter", function () {
          // Use the card URL from data attribute (resolved by CardHandler)
          const cardUrl = this.dataset.cardUrl || this.href;

          // Delay showing tooltip slightly to avoid flickering
          hoverTimeout = setTimeout(() => {
            showTooltipForUrl(cardUrl, this);
          }, 300);
        });

        link.addEventListener("mouseleave", function () {
          if (hoverTimeout) {
            clearTimeout(hoverTimeout);
            hoverTimeout = null;
          }
          setTimeout(removeTooltip, 200);
        });
      });
    },
    { id: "scryfall-tooltips" }
  );

  // Remove tooltip when scrolling
  window.addEventListener("scroll", removeTooltip, { passive: true });
}

function showTooltipForUrl(url, anchor) {
  removeTooltip();

  // Check cache first
  if (fetchCache.has(url)) {
    const html = fetchCache.get(url);
    displayTooltip(html, anchor);
    return;
  }

  // Fetch full onebox for the card URL
  ajax("/onebox", {
    data: { url, refresh: false },
  })
    .then((data) => {
      if (data && data.preview) {
        // Cache the result
        fetchCache.set(url, data.preview);
        displayTooltip(data.preview, anchor);
      }
    })
    .catch(() => {
      // Silently fail - tooltip won't show
    });
}

function displayTooltip(html, anchor) {
  const tooltip = document.createElement("div");
  tooltip.className = "scryfall-tooltip";

  // Wrap the onebox HTML in our tooltip container
  tooltip.innerHTML = `
    <div class="scryfall-tooltip-content">
      ${html}
    </div>
  `;

  document.body.appendChild(tooltip);
  currentTooltip = tooltip;

  // Position after appending to get accurate measurements
  requestAnimationFrame(() => {
    positionTooltip(tooltip, anchor);
  });

  // Allow clicking links in tooltip
  tooltip.addEventListener("mouseenter", () => {
    tooltip.style.pointerEvents = "auto";
  });

  tooltip.addEventListener("mouseleave", () => {
    removeTooltip();
  });
}

function positionTooltip(tooltip, anchor) {
  const rect = anchor.getBoundingClientRect();
  const tooltipRect = tooltip.getBoundingClientRect();

  // Position below the link, centered
  let left =
    rect.left + window.scrollX + rect.width / 2 - tooltipRect.width / 2;
  let top = rect.bottom + window.scrollY + 10;

  // Keep tooltip on screen
  const padding = 10;
  const viewportWidth = window.innerWidth;
  const viewportHeight = window.innerHeight;

  if (left < padding) {
    left = padding;
  } else if (left + tooltipRect.width > viewportWidth - padding) {
    left = viewportWidth - tooltipRect.width - padding;
  }

  // Check if tooltip would go off bottom of viewport
  if (rect.bottom + tooltipRect.height + 10 > viewportHeight) {
    // Position above if no room below
    top = rect.top + window.scrollY - tooltipRect.height - 10;
  }

  tooltip.style.left = `${left}px`;
  tooltip.style.top = `${top}px`;
}

function removeTooltip() {
  if (currentTooltip) {
    currentTooltip.remove();
    currentTooltip = null;
  }
}

export default {
  name: "scryfall-tooltip",
  initialize() {
    withPluginApi("0.11.1", initializeScryfallTooltips);
  },
};