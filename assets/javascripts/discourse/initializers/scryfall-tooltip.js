import { ajax } from "discourse/lib/ajax";
import { withPluginApi } from "discourse/lib/plugin-api";

let currentTooltip = null;
let fetchCache = new Map();

// Detect if we're on mobile/touch device
const isMobileDevice = () => {
  return (
    /Mobi|Android|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(
      navigator.userAgent
    ) || "ontouchstart" in window
  );
};

function initializeScryfallTooltips(api) {
  console.log("[Scryfall] Initializing tooltips");
  const isMobile = isMobileDevice();
  console.log(`[Scryfall] Device type: ${isMobile ? "mobile" : "desktop"}`);

  api.decorateCookedElement(
    (element) => {
      // Find all Scryfall inline oneboxes (may or may not already have our class)
      const scryfallLinks = element.querySelectorAll(
        'a.inline-onebox[href*="scryfall.com"], a.scryfall-card-link'
      );

      console.log(`[Scryfall] Found ${scryfallLinks.length} Scryfall links`);

      scryfallLinks.forEach((link) => {
        console.log(
          "[Scryfall] Processing link:",
          link.href,
          "Classes:",
          link.className
        );
        // Add custom class if not already present
        if (!link.classList.contains("scryfall-card-link")) {
          link.classList.add("scryfall-card-link");

          // Extract card name from the link text (only if we're adding the class)
          const linkText = link.textContent.trim();

          // If it's the full onebox format with · separators, extract just the card name
          if (linkText.includes(" · ")) {
            const cardName = linkText.split(" · ")[0].trim();
            link.textContent = cardName;
          }
          // If the text is just "scryfall.com" or a URL, extract from href
          else if (
            linkText.includes("scryfall.com") ||
            linkText.includes(".")
          ) {
            const match = link.href.match(/\/card\/[^/]+\/[^/]+\/([^/]+)$/);
            if (match) {
              const slug = match[1];
              const cardName = slug
                .split("-")
                .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
                .join(" ");
              link.textContent = cardName;
            }
          }
        }

        // Prevent duplicate event listeners
        if (link.dataset.tooltipInitialized) {
          return;
        }
        link.dataset.tooltipInitialized = "true";

        if (isMobile) {
          // Mobile: tap to toggle card preview
          link.addEventListener("click", function (e) {
            e.preventDefault();
            const cardUrl = this.href;
            toggleMobileCard(cardUrl, this);
          });
        } else {
          // Desktop: hover to show tooltip
          let hoverTimeout = null;

          link.addEventListener("mouseenter", function () {
            const cardUrl = this.href;
            console.log("[Scryfall] Mouse enter, will fetch:", cardUrl);

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
        }
      });
    },
    { id: "scryfall-tooltips" }
  );

  // Remove tooltip when scrolling (desktop only)
  if (!isMobile) {
    window.addEventListener("scroll", removeTooltip, { passive: true });
  }
}

function showTooltipForUrl(url, anchor) {
  console.log("[Scryfall] showTooltipForUrl called with:", url);
  removeTooltip();

  // Check cache first
  if (fetchCache.has(url)) {
    console.log("[Scryfall] Using cached onebox");
    const html = fetchCache.get(url);
    displayTooltip(html, anchor);
    return;
  }

  console.log("[Scryfall] Fetching onebox from /onebox");
  // Fetch full onebox for the card URL
  ajax("/onebox", {
    data: { url, refresh: false },
    dataType: "html",
  })
    .then((html) => {
      console.log("[Scryfall] Onebox HTML received, length:", html?.length);
      if (html) {
        // Cache the result
        fetchCache.set(url, html);
        displayTooltip(html, anchor);
      } else {
        console.warn("[Scryfall] Empty HTML in onebox response");
      }
    })
    .catch((error) => {
      console.error("[Scryfall] Error fetching onebox:", error);
      // Even on "error", check if we got HTML in the response
      if (error.jqXHR && error.jqXHR.responseText) {
        console.log("[Scryfall] Found HTML in error response, using it");
        const html = error.jqXHR.responseText;
        fetchCache.set(url, html);
        displayTooltip(html, anchor);
      }
      // Otherwise silently fail - tooltip won't show
    });
}

function displayTooltip(html, anchor) {
  console.log("[Scryfall] displayTooltip called with html length:", html?.length);
  
  const tooltip = document.createElement("div");
  tooltip.className = "scryfall-tooltip";
  tooltip.style.position = "absolute";
  tooltip.style.zIndex = "1000";
  tooltip.style.visibility = "hidden"; // Hide until positioned

  // Wrap the onebox HTML in our tooltip container
  tooltip.innerHTML = `
    <div class="scryfall-tooltip-content">
      ${html}
    </div>
  `;

  document.body.appendChild(tooltip);
  currentTooltip = tooltip;
  
  console.log("[Scryfall] Tooltip appended to body");

  // Position after DOM update and make visible
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      positionTooltip(tooltip, anchor);
      tooltip.style.visibility = "visible";
      console.log("[Scryfall] Tooltip positioned at:", tooltip.style.left, tooltip.style.top);
    });
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

function toggleMobileCard(url, anchor) {
  console.log("Toggle mobile modal for:", url);

  // Remove any existing modal
  document.querySelectorAll('.modal.scryfall-mobile-modal').forEach(modal => modal.remove());

  // Create modal overlay (Discourse uses .modal)
  const overlay = document.createElement('div');
  overlay.className = 'modal scryfall-mobile-modal';

  // Modal inner container (Discourse uses .modal-inner-container)
  const modalInner = document.createElement('div');
  modalInner.className = 'modal-inner-container';

  // Close button (Discourse uses .close)
  const closeButton = document.createElement('button');
  closeButton.className = 'close';
  closeButton.type = 'button';
  closeButton.innerHTML = '<span aria-hidden="true">×</span>';
  closeButton.onclick = (e) => {
    e.stopPropagation();
    overlay.remove();
  };

  // Modal content
  const modalContent = document.createElement('div');
  modalContent.className = 'scryfall-mobile-modal-content';

  // Add loading indicator
  const loading = document.createElement('div');
  loading.className = 'scryfall-mobile-card-loading';
  loading.textContent = 'Loading...';
  modalContent.appendChild(loading);

  modalInner.appendChild(closeButton);
  modalInner.appendChild(modalContent);
  overlay.appendChild(modalInner);
  document.body.appendChild(overlay);

  // Dismiss modal on overlay tap (not on modal itself)
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) {
      overlay.remove();
    }
  });

  // Fetch onebox HTML (with cache)
  function showHtml(html) {
    loading.remove();
    modalContent.innerHTML += html;
  }
  if (fetchCache.has(url)) {
    showHtml(fetchCache.get(url));
    return;
  }
  ajax("/onebox", {
    data: { url, refresh: false },
    dataType: "html",
  })
    .then((html) => {
      fetchCache.set(url, html);
      showHtml(html);
    })
    .catch((error) => {
      let html = '';
      if (error.jqXHR && error.jqXHR.responseText) {
        html = error.jqXHR.responseText;
        fetchCache.set(url, html);
        showHtml(html);
      } else {
        loading.remove();
        modalContent.innerHTML += '<div class="scryfall-mobile-card-error">Error loading card preview</div>';
      }
    });
}

export default {
  name: "scryfall-tooltip",
  initialize() {
    withPluginApi("0.11.1", initializeScryfallTooltips);
  },
};