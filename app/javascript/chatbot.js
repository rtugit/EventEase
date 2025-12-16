// ===================================
// CHATBOT FUNCTIONALITY
// ===================================

// ===================================
// CHATBOT & AI WRITE FUNCTIONALITY
// ===================================

const initAI = () => {
  initChatbot();
  initAIWrite();
};

document.addEventListener('turbo:load', initAI);
document.addEventListener('DOMContentLoaded', initAI);

// --- Chatbot Logic ---
function initChatbot() {
  const chatToggleBtn = document.getElementById('chatToggleBtn');
  const chatCloseBtn = document.getElementById('chatCloseBtn');
  const chatbotOverlay = document.getElementById('chatbotOverlay');
  const chatForm = document.getElementById('chatForm');
  const chatInput = document.getElementById('chatInput');
  const chatMessages = document.getElementById('chatMessages');
  const chatOptions = document.querySelectorAll('.chatbot-checkbox');

  if (!chatToggleBtn || !chatbotOverlay) return;

  // Remove existing listeners if any (though unlikely with Turbo replacing DOM)
  // We recommend using named functions for listeners if we need to remove them, 
  // but since elements are replaced, we can just attach new ones.

  // Toggle chat modal
  chatToggleBtn.onclick = function() {
    chatbotOverlay.classList.add('active');
    setTimeout(() => chatInput?.focus(), 100);
  };

  if (chatCloseBtn) {
    chatCloseBtn.onclick = function() {
      chatbotOverlay.classList.remove('active');
    };
  }

  // Close on overlay click
  chatbotOverlay.onclick = function(e) {
    if (e.target === chatbotOverlay) {
      chatbotOverlay.classList.remove('active');
    }
  };

  // Handle option clicks - populate input immediately
  chatOptions.forEach(checkbox => {
    checkbox.onclick = function() {
      // Uncheck other options
      chatOptions.forEach(cb => {
        if (cb !== checkbox) cb.checked = false;
      });

      // Populate input with the option text
      const optionText = checkbox.nextElementSibling.textContent.trim();
      if (checkbox.checked) {
        chatInput.value = optionText;
        chatInput.focus();
      } else {
        chatInput.value = '';
      }
    };
  });

  // Handle chat form submission
  if (chatForm) {
    chatForm.onsubmit = async function(e) {
      e.preventDefault();
      
      const message = chatInput.value.trim();
      if (!message) return;

      // Uncheck all options before sending
      chatOptions.forEach(cb => cb.checked = false);

      // Add user message to chat
      addMessage(message, 'user', chatMessages);
      chatInput.value = '';

      // Show loading
      const loadingEl = showLoading(chatMessages);

      try {
        const response = await fetch('/ai/chat', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': getCSRFToken()
          },
          body: JSON.stringify({
            message: message,
            options: [] // no longer sending options as context, message is self-contained
          })
        });

        const data = await response.json();
        
        if (loadingEl) loadingEl.remove();

        if (data.status === 'success') {
          addMessage(data.message, 'ai', chatMessages);
        } else {
          addMessage('Sorry, I encountered an error. Please try again.', 'ai', chatMessages);
        }

      } catch (error) {
        console.error('Chat error:', error);
        if (loadingEl) loadingEl.remove();
        addMessage('Sorry, I\'m having trouble connecting. Please try again.', 'ai', chatMessages);
      }
    };
  }
}

// --- AI Write Logic ---
function initAIWrite() {
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
  aiWriteBtn.onclick = function() {
    if (!aiPromptContainer) return;
    const isVisible = aiPromptContainer.style.display !== 'none';
    aiPromptContainer.style.display = isVisible ? 'none' : 'block';
    if (!isVisible) {
      aiPromptInput?.focus();
    }
  };

  // Cancel AI prompt
  if (aiCancelBtn) {
    aiCancelBtn.onclick = function() {
      if (aiPromptContainer) aiPromptContainer.style.display = 'none';
      if (aiPromptInput) aiPromptInput.value = '';
    };
  }

  // Generate new content
  if (aiGenerateBtn) {
    aiGenerateBtn.onclick = async function() {
      await generateContent('generate', { aiPromptInput, eventDescription, aiPromptContainer, aiLoading, aiGenerateBtn, aiEnhanceBtn });
    };
  }

  // Enhance existing content
  if (aiEnhanceBtn) {
    aiEnhanceBtn.onclick = async function() {
      await generateContent('enhance', { aiPromptInput, eventDescription, aiPromptContainer, aiLoading, aiGenerateBtn, aiEnhanceBtn });
    };
  }
}

// --- Helpers ---

async function generateContent(action, elements) {
  const { aiPromptInput, eventDescription, aiPromptContainer, aiLoading, aiGenerateBtn, aiEnhanceBtn } = elements;
  
  const prompt = aiPromptInput.value.trim();
  const existingText = eventDescription.value.trim();

  if (action === 'enhance' && !existingText) {
    alert('Please write some content first to enhance it.');
    return;
  }

  // Show loading
  if (aiLoading) aiLoading.style.display = 'flex';
  if (aiGenerateBtn) aiGenerateBtn.disabled = true;
  if (aiEnhanceBtn) aiEnhanceBtn.disabled = true;

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
      if (eventDescription) eventDescription.value = data.content;
      if (aiPromptContainer) aiPromptContainer.style.display = 'none';
      if (aiPromptInput) aiPromptInput.value = '';
    } else {
      alert('Failed to generate content. Please try again.');
    }

  } catch (error) {
    console.error('AI content generation error:', error);
    alert('Failed to generate content. Please try again.');
  } finally {
    if (aiLoading) aiLoading.style.display = 'none';
    if (aiGenerateBtn) aiGenerateBtn.disabled = false;
    if (aiEnhanceBtn) aiEnhanceBtn.disabled = false;
  }
}

function addMessage(text, sender, container) {
  if (!container) return;
  const messageEl = document.createElement('div');
  messageEl.className = `chat-message ${sender}`;
  messageEl.textContent = text;
  container.appendChild(messageEl);
  container.scrollTop = container.scrollHeight;
}

function showLoading(container) {
  if (!container) return null;
  const loadingEl = document.createElement('div');
  loadingEl.className = 'chatbot-loading';
  loadingEl.innerHTML = '<span class="chatbot-loading-spinner"></span><span>Thinking...</span>';
  container.appendChild(loadingEl);
  container.scrollTop = container.scrollHeight;
  return loadingEl;
}

function getCSRFToken() {
  const meta = document.querySelector('meta[name="csrf-token"]');
  return meta ? meta.content : '';
}
