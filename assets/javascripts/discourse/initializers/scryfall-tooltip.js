import { withPluginApi } from "discourse/lib/plugin-api";

let currentTooltip = null;

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

        link.addEventListener("mouseenter", function(e) {
          removeTooltip();
          
          const cardData = {
            name: this.dataset.cardName,
            image: this.dataset.cardImage,
            description: this.dataset.cardDescription
          };
          
          // Only show tooltip if we have an image
          if (cardData.image && cardData.image.trim() !== "") {
            currentTooltip = createTooltip(cardData);
            document.body.appendChild(currentTooltip);
            
            // Position after appending to get accurate measurements
            requestAnimationFrame(() => {
              positionTooltip(currentTooltip, this);
            });
          }
        });

        link.addEventListener("mouseleave", function() {
          setTimeout(removeTooltip, 200);
        });
      });
    },
    { id: "scryfall-tooltips" }
  );

  // Remove tooltip when scrolling
  window.addEventListener("scroll", removeTooltip, { passive: true });
}

function createTooltip(cardData) {
  const tooltip = document.createElement("div");
  tooltip.className = "scryfall-tooltip";
  
  const descriptionHtml = cardData.description && cardData.description.trim()
    ? `<div class="card-description">${escapeHtml(cardData.description)}</div>`
    : "";
  
  tooltip.innerHTML = `
    <div class="scryfall-tooltip-content">
      <img src="${escapeHtml(cardData.image)}" 
           alt="${escapeHtml(cardData.name || 'Card')}" 
           class="scryfall-card-image">
      <div class="card-info">
        <div class="card-name">${escapeHtml(cardData.name || 'Card')}</div>
        ${descriptionHtml}
      </div>
    </div>
  `;
  
  return tooltip;
}

function positionTooltip(tooltip, anchor) {
  const rect = anchor.getBoundingClientRect();
  const tooltipRect = tooltip.getBoundingClientRect();
  
  // Position below the link, centered
  let left = rect.left + window.scrollX + (rect.width / 2) - (tooltipRect.width / 2);
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

function escapeHtml(text) {
  if (!text) return "";
  const div = document.createElement("div");
  div.textContent = text;
  return div.innerHTML;
}

export default {
  name: "scryfall-tooltip",
  initialize() {
    withPluginApi("0.11.1", initializeScryfallTooltips);
  }
};