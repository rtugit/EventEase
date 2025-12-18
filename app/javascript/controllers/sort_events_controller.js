import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="sort-events"
export default class extends Controller {
  connect() {
  console.log("Hello")
  function initSortEvents() {
  // Remove old listeners first
  const oldSelect = document.getElementById('sort-events');
  if (oldSelect) {
    const newSelect = oldSelect.cloneNode(true);
    oldSelect.parentNode.replaceChild(newSelect, oldSelect);
  }

  const sortSelect = document.getElementById('sort-events');

  if (!sortSelect) {
    return;
  }

  // Check if coming from sort change
  const isFromSort = sessionStorage.getItem('sortScrollY');

  if (isFromSort) {
    // Restore scroll position if coming from sort change
    setTimeout(() => {
      window.scrollTo(0, parseInt(isFromSort));
      sessionStorage.removeItem('sortScrollY');
    }, 50);

    // Remove hash from URL
    if (window.location.hash) {
      history.replaceState(null, '', window.location.pathname + window.location.search);
    }
  } else {
    // Fresh page load/refresh - check if sort param exists
    const url = new URL(window.location.href);
    if (url.searchParams.has('sort')) {
      // Remove sort param and reload page
      url.searchParams.delete('sort');
      url.hash = '';
      window.location.replace(url.toString());
      return; // Stop execution, page will reload
    }
  }

  sortSelect.addEventListener('change', function(e) {
    e.preventDefault();

    // Save current scroll position
    sessionStorage.setItem('sortScrollY', window.scrollY.toString());

    const sortValue = this.value;
    const url = new URL(window.location.href);
    url.searchParams.set('sort', sortValue);
    url.hash = '';

    window.location.href = url.toString();
  });
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', initSortEvents);
document.addEventListener('turbo:load', initSortEvents);
document.addEventListener('turbo:render', initSortEvents);

  }
}
