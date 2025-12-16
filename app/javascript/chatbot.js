// ===================================
// CHATBOT FUNCTIONALITY
// ===================================

document.addEventListener('DOMContentLoaded', function() {
  const chatToggleBtn = document.getElementById('chatToggleBtn');
  const chatCloseBtn = document.getElementById('chatCloseBtn');
  const chatbotOverlay = document.getElementById('chatbotOverlay');
  const chatForm = document.getElementById('chatForm');
  const chatInput = document.getElementById('chatInput');
  const chatMessages = document.getElementById('chatMessages');
  const chatOptions = document.querySelectorAll('.chatbot-checkbox');

  if (!chatToggleBtn || !chatbotOverlay) return;

  // Toggle chat modal
  chatToggleBtn.addEventListener('click', function() {
    chatbotOverlay.classList.add('active');
    chatInput.focus();
  });

  chatCloseBtn.addEventListener('click', function() {
    chatbotOverlay.classList.remove('active');
  });

  // Close on overlay click
  chatbotOverlay.addEventListener('click', function(e) {
    if (e.target === chatbotOverlay) {
      chatbotOverlay.classList.remove('active');
    }
  });

  // Handle chat form submission
  chatForm.addEventListener('submit', async function(e) {
    e.preventDefault();
    
    const message = chatInput.value.trim();
    if (!message) return;

    // Get selected options
    const selectedOptions = Array.from(chatOptions)
      .filter(cb => cb.checked)
      .map(cb => cb.value);

    // Add user message to chat
    addMessage(message, 'user');
    chatInput.value = '';

    // Show loading
    const loadingEl = showLoading();

    try {
      // Send to backend
      const response = await fetch('/ai/chat', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': getCSRFToken()
        },
        body: JSON.stringify({
          message: message,
          options: selectedOptions
        })
      });

      const data = await response.json();
      
      // Remove loading
      if (loadingEl) loadingEl.remove();

      // Add AI response
      if (data.status === 'success') {
        addMessage(data.message, 'ai');
      } else {
        addMessage('Sorry, I encountered an error. Please try again.', 'ai');
      }

      // Uncheck options after first response
      chatOptions.forEach(cb => cb.checked = false);

    } catch (error) {
      console.error('Chat error:', error);
      if (loadingEl) loadingEl.remove();
      addMessage('Sorry, I\'m having trouble connecting. Please try again.', 'ai');
    }
  });

  // Helper: Add message to chat
  function addMessage(text, sender) {
    const messageEl = document.createElement('div');
    messageEl.className = `chat-message ${sender}`;
    messageEl.textContent = text;
    chatMessages.appendChild(messageEl);
    chatMessages.scrollTop = chatMessages.scrollHeight;
  }

  // Helper: Show loading indicator
  function showLoading() {
    const loadingEl = document.createElement('div');
    loadingEl.className = 'chatbot-loading';
    loadingEl.innerHTML = '<span class="chatbot-loading-spinner"></span><span>Thinking...</span>';
    chatMessages.appendChild(loadingEl);
    chatMessages.scrollTop = chatMessages.scrollHeight;
    return loadingEl;
  }

  // Helper: Get CSRF token
  function getCSRFToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.content : '';
  }
});

// ===================================
// AI WRITE FUNCTIONALITY
// ===================================

document.addEventListener('DOMContentLoaded', function() {
  const aiWriteBtn = document.getElementById('aiWriteBtn');
  const aiPromptContainer = document.getElementById('aiPromptContainer');
  const aiPromptInput = document.getElementById('aiPromptInput');
  const aiGenerateBtn = document.getElementById('aiGenerateBtn');
  const aiEnhanceBtn = document.getElementById('aiEnhanceBtn');
  const aiCancelBtn = document.getElementById('aiCancelBtn');
  const aiLoading = document.getElementById('aiLoading');
  const eventDescription = document.getElementById('eventDescription');

  if (!aiWriteBtn) return;

  // Toggle AI prompt interface
  aiWriteBtn.addEventListener('click', function() {
    const isVisible = aiPromptContainer.style.display !== 'none';
    aiPromptContainer.style.display = isVisible ? 'none' : 'block';
    if (!isVisible) {
      aiPromptInput.focus();
    }
  });

  // Cancel AI prompt
  aiCancelBtn.addEventListener('click', function() {
    aiPromptContainer.style.display = 'none';
    aiPromptInput.value = '';
  });

  // Generate new content
  aiGenerateBtn.addEventListener('click', async function() {
    await generateContent('generate');
  });

  // Enhance existing content
  aiEnhanceBtn.addEventListener('click', async function() {
    await generateContent('enhance');
  });

  async function generateContent(action) {
    const prompt = aiPromptInput.value.trim();
    const existingText = eventDescription.value.trim();

    if (action === 'enhance' && !existingText) {
      alert('Please write some content first to enhance it.');
      return;
    }

    // Show loading
    aiLoading.style.display = 'flex';
    aiGenerateBtn.disabled = true;
    aiEnhanceBtn.disabled = true;

    try {
      const response = await fetch('/ai/generate_content', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': getCSRFToken()
        },
        body: JSON.stringify({
          prompt: prompt,
          existing_text: existingText,
          action: action
        })
      });

      const data = await response.json();

      if (data.status === 'success') {
        eventDescription.value = data.content;
        aiPromptContainer.style.display = 'none';
        aiPromptInput.value = '';
      } else {
        alert('Failed to generate content. Please try again.');
      }

    } catch (error) {
      console.error('AI content generation error:', error);
      alert('Failed to generate content. Please try again.');
    } finally {
      aiLoading.style.display = 'none';
      aiGenerateBtn.disabled = false;
      aiEnhanceBtn.disabled = false;
    }
  }

  function getCSRFToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.content : '';
  }
});
