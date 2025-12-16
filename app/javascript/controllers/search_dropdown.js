// app/javascript/controllers/search_dropdown.js

function initSearchDropdown() {
  const titleInput = document.getElementById('search_title');
  const locationInput = document.getElementById('search_location');
  const titleDropdown = document.getElementById('title-dropdown');
  const locationDropdown = document.getElementById('location-dropdown');
  const searchForm = document.querySelector('.search-form');
  const dateInput = document.getElementById('search_date');

  // Date input color handling
  if (dateInput) {
    if (dateInput.value) {
      dateInput.classList.add('has-value');
    }

    dateInput.addEventListener('change', function() {
      if (this.value) {
        this.classList.add('has-value');
      } else {
        this.classList.remove('has-value');
      }
    });
  }

  if (!titleInput || !locationInput) {
    console.log('Search inputs not found');
    return;
  }

  console.log('Search dropdown initialized');

  let debounceTimer;

  function debounce(func, delay) {
    return function(...args) {
      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(() => func.apply(this, args), delay);
    };
  }

  async function fetchSuggestions(query, type) {
    if (query.length < 2) return [];

    try {
      const response = await fetch(`/events/search_suggestions?q=${encodeURIComponent(query)}&type=${type}`);
      if (response.ok) {
        return await response.json();
      }
    } catch (error) {
      console.error('Error fetching suggestions:', error);
    }
    return [];
  }

  function highlightMatch(text, query) {
    if (!query) return text;
    const regex = new RegExp(`(${query})`, 'gi');
    return text.replace(regex, '<strong>$1</strong>');
  }

  function renderDropdown(dropdown, suggestions, input) {
    if (suggestions.length === 0) {
      dropdown.classList.remove('active');
      dropdown.innerHTML = '';
      return;
    }

    dropdown.innerHTML = suggestions.map(item => `
      <div class="dropdown-item" data-value="${item.value}">
        <span>${highlightMatch(item.label, input.value)}</span>
      </div>
    `).join('');

    dropdown.classList.add('active');

    dropdown.querySelectorAll('.dropdown-item').forEach(item => {
      item.addEventListener('click', function() {
        input.value = this.dataset.value;
        dropdown.classList.remove('active');
        dropdown.innerHTML = '';
        searchForm.submit();
      });
    });
  }

  const handleTitleInput = debounce(async function() {
    const query = titleInput.value.trim();
    const suggestions = await fetchSuggestions(query, 'title');
    renderDropdown(titleDropdown, suggestions, titleInput);
  }, 300);

  const handleLocationInput = debounce(async function() {
    const query = locationInput.value.trim();
    const suggestions = await fetchSuggestions(query, 'location');
    renderDropdown(locationDropdown, suggestions, locationInput);
  }, 300);

  titleInput.addEventListener('input', handleTitleInput);
  locationInput.addEventListener('input', handleLocationInput);

  document.addEventListener('click', function(e) {
    if (!e.target.closest('.search-input-wrapper')) {
      if (titleDropdown) titleDropdown.classList.remove('active');
      if (locationDropdown) locationDropdown.classList.remove('active');
    }
  });

  function handleKeyboard(input, dropdown) {
    input.addEventListener('keydown', function(e) {
      const items = dropdown.querySelectorAll('.dropdown-item');
      const activeItem = dropdown.querySelector('.dropdown-item.active');
      let index = Array.from(items).indexOf(activeItem);

      if (e.key === 'ArrowDown') {
        e.preventDefault();
        index = index < items.length - 1 ? index + 1 : 0;
        items.forEach(item => item.classList.remove('active'));
        items[index]?.classList.add('active');
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        index = index > 0 ? index - 1 : items.length - 1;
        items.forEach(item => item.classList.remove('active'));
        items[index]?.classList.add('active');
      } else if (e.key === 'Enter' && activeItem) {
        e.preventDefault();
        input.value = activeItem.dataset.value;
        dropdown.classList.remove('active');
        searchForm.submit();
      } else if (e.key === 'Escape') {
        dropdown.classList.remove('active');
      }
    });
  }

  handleKeyboard(titleInput, titleDropdown);
  handleKeyboard(locationInput, locationDropdown);
}

document.addEventListener('DOMContentLoaded', initSearchDropdown);
document.addEventListener('turbo:load', initSearchDropdown);
