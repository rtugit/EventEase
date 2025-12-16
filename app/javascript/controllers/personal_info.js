document.addEventListener('DOMContentLoaded', function() {
  const genderSelect = document.querySelector('.form-select');

  if (genderSelect) {
    // Check on load
    if (genderSelect.value && genderSelect.value !== '') {
      genderSelect.classList.add('has-value');
    }

    // Check on change
    genderSelect.addEventListener('change', function() {
      if (this.value && this.value !== '') {
        this.classList.add('has-value');
      } else {
        this.classList.remove('has-value');
      }
    });
  }
});

document.addEventListener('turbo:load', function() {
  const genderSelect = document.querySelector('.form-select');

  if (genderSelect) {
    if (genderSelect.value && genderSelect.value !== '') {
      genderSelect.classList.add('has-value');
    }

    genderSelect.addEventListener('change', function() {
      if (this.value && this.value !== '') {
        this.classList.add('has-value');
      } else {
        this.classList.remove('has-value');
      }
    });
  }
});
