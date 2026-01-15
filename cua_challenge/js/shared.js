// Shared JavaScript for CUA Challenge

// Random Modal Popup System
let modalShown = false;

function showRandomModal() {
  if (modalShown) return;

  const modal = document.getElementById('randomModal');
  if (!modal) return;

  // Show modal after random delay (3-8 seconds)
  const delay = Math.floor(Math.random() * 5000) + 3000;

  setTimeout(() => {
    if (!modalShown) {
      modal.classList.remove('hidden');
      modalShown = true;
    }
  }, delay);
}

function closeModal(modalId) {
  const modal = document.getElementById(modalId);
  if (modal) {
    modal.classList.add('hidden');
  }
}

// Form validation helper
function validateForm(formId) {
  const form = document.getElementById(formId);
  if (!form) return false;

  const inputs = form.querySelectorAll('input[required], select[required], textarea[required]');
  let isValid = true;

  inputs.forEach(input => {
    if (!input.value || input.value.trim() === '') {
      isValid = false;
      input.classList.add('border-red-500');
    } else {
      input.classList.remove('border-red-500');
    }
  });

  return isValid;
}

// Show error message
function showError(message) {
  const errorDiv = document.getElementById('errorMessage');
  if (errorDiv) {
    errorDiv.textContent = message;
    errorDiv.classList.remove('hidden');
    setTimeout(() => {
      errorDiv.classList.add('hidden');
    }, 3000);
  }
}

// Format validation helpers
function validateEmail(email) {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return re.test(email);
}

function validatePhone(phone) {
  const re = /^\d{3}-\d{3}-\d{4}$/;
  return re.test(phone);
}

function validateZipCode(zip) {
  const re = /^\d{5}$/;
  return re.test(zip);
}

function validateDateOfBirth(dob) {
  const re = /^\d{4}-\d{2}-\d{2}$/;
  return re.test(dob);
}

// Initialize modal system on page load
document.addEventListener('DOMContentLoaded', () => {
  if (document.getElementById('randomModal')) {
    showRandomModal();
  }
});

// Searchable dropdown implementation
function initSearchableDropdown(inputId, listId, hiddenInputId) {
  const input = document.getElementById(inputId);
  const list = document.getElementById(listId);
  const hiddenInput = document.getElementById(hiddenInputId);

  if (!input || !list) return;

  input.addEventListener('focus', () => {
    list.classList.remove('hidden');
  });

  input.addEventListener('input', (e) => {
    const filter = e.target.value.toLowerCase();
    const items = list.querySelectorAll('li');

    items.forEach(item => {
      const text = item.textContent.toLowerCase();
      if (text.includes(filter)) {
        item.classList.remove('hidden');
      } else {
        item.classList.add('hidden');
      }
    });

    list.classList.remove('hidden');
  });

  list.addEventListener('click', (e) => {
    if (e.target.tagName === 'LI') {
      input.value = e.target.textContent;
      if (hiddenInput) {
        hiddenInput.value = e.target.dataset.value;
      }
      list.classList.add('hidden');
    }
  });

  document.addEventListener('click', (e) => {
    if (!input.contains(e.target) && !list.contains(e.target)) {
      list.classList.add('hidden');
    }
  });
}

// Table search functionality
function initTableSearch(searchId, tableId) {
  const searchInput = document.getElementById(searchId);
  const table = document.getElementById(tableId);

  if (!searchInput || !table) return;

  searchInput.addEventListener('input', (e) => {
    const filter = e.target.value.toLowerCase();
    const rows = table.querySelectorAll('tbody tr');

    rows.forEach(row => {
      const text = row.textContent.toLowerCase();
      if (text.includes(filter)) {
        row.classList.remove('hidden');
      } else {
        row.classList.add('hidden');
      }
    });
  });
}

// Collapsible section
function toggleCollapsible(buttonId, contentId) {
  const button = document.getElementById(buttonId);
  const content = document.getElementById(contentId);

  if (!button || !content) return;

  button.addEventListener('click', () => {
    const isHidden = content.classList.contains('hidden');
    if (isHidden) {
      content.classList.remove('hidden');
      button.querySelector('.arrow')?.classList.add('rotate-180');
    } else {
      content.classList.add('hidden');
      button.querySelector('.arrow')?.classList.remove('rotate-180');
    }
  });
}
