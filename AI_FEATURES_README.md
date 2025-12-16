# AI Features Implementation for EventEase

## Overview

This implementation adds two core AI features to the EventEase event management platform:

1. **AI Customer Service Chatbot** ("Ask Eventes")
2. **AI Writing Assistant** for event descriptions

## Features Implemented

### 1. AI Customer Service Chatbot

**Location**: Floating button in bottom-right corner (all pages)

**Components**:

- Floating action button with "Ask Eventes" label
- Modal chat interface with:
  - Event-related quick options (checkboxes)
  - Chat history
  - Message input field
  - Disclaimer footer

**Files Created**:

- `app/views/layouts/_chat_button.html.erb` - Floating chat button
- `app/views/layouts/_chat_modal.html.erb` - Chat modal interface
- `app/assets/stylesheets/chatbot.css` - Chat styles (mobile-first)
- `app/assets/javascripts/chatbot.js` - Chat functionality
- `app/controllers/ai_controller.rb` - Backend endpoint for chat

**Endpoint**: `POST /ai/chat`

**Quick Options**:

- I want to create an event
- I need help selling tickets
- I want to manage my event
- I need help with event promotion
- I have questions about ticket pricing

### 2. AI Writing Assistant

**Location**: Event creation/edit page, description field

**Components**:

- "AI Write" button with sparkles icon
- Prompt input field
- Generate/Enhance options
- Loading states

**Files Created**:

- `app/views/events/_description_field.html.erb` - Description field with AI
- `app/assets/stylesheets/events.css` - Event form AI styles
- JavaScript in `chatbot.js` handles AI Write functionality

**Endpoint**: `POST /ai/generate_content`

**Actions**:

- **Generate New**: Create fresh event description from prompt
- **Enhance Existing**: Improve current description text

## File Structure

```
app/
├── controllers/
│   └── ai_controller.rb                    # AI endpoints
├── views/
│   ├── layouts/
│   │   ├── _chat_button.html.erb          # Chat floating button
│   │   └── _chat_modal.html.erb           # Chat modal
│   └── events/
│       └── _description_field.html.erb     # AI-enhanced description field
├── assets/
│   ├── stylesheets/
│   │   ├── chatbot.css                     # Chat UI styles
│   │   └── events.css                      # Event form AI styles
│   └── javascripts/
│       └── chatbot.js                      # All AI functionality JS
```

## Integration Points

### Application Layout

The chat widget is added to `app/views/layouts/application.html.erb`:

```erb
<%= render "layouts/chat_button" %>
<%= render "layouts/chat_modal" %>
```

### Event Form

The description field is replaced in `app/views/events/_form.html.erb`:

```erb
<%= render 'events/description_field', f: f %>
```

### Routes

Added in `config/routes.rb`:

```ruby
post 'ai/chat', to: 'ai#chat'
post 'ai/generate_content', to: 'ai#generate_content'
```

## Backend Integration (TODO)

The `AiController` currently returns placeholder responses. To integrate with Ruby LLM:

1. **Install LLM gem** (e.g., `ruby-openai`, `anthropic`, or custom Ruby LLM)
2. **Update `generate_chat_response` method** in `ai_controller.rb`
3. **Update `generate_event_description` method** in `ai_controller.rb`
4. **Add API keys** to Rails credentials or environment variables

Example integration points are marked with `# TODO: Integrate with Ruby LLM` comments.

## Design System

### Colors

- Primary button: `#122927`
- Hover states: `#1a3a37`
- Light background: `#f5f8f7`
- Border: `#e0e0e0`
- Text: `#333333`
- Secondary text: `#666666`

### Responsive Behavior

- **Desktop**: Full features visible
- **Mobile** (< 600px):
  - Chat button shows only icon (hides "Ask Eventes" text)
  - Chat modal goes full-screen
  - Buttons stack vertically

## Usage

### For Users

**Using the Chatbot**:

1. Click "Ask Eventes" button (bottom-right corner)
2. Select relevant quick options (optional)
3. Type question and press Enter or click Send
4. View AI response in chat history

**Using AI Write**:

1. Go to event creation/edit page
2. Click "AI Write" button above description field
3. (Optional) Enter a prompt describing the event
4. Click "Generate New" or "Enhance Existing"
5. AI-generated content appears in description field

### For Developers

**Testing Endpoints**:

```bash
# Chat endpoint
curl -X POST http://localhost:3000/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "How do I create an event?", "options": ["create_event"]}'

# Content generation endpoint
curl -X POST http://localhost:3000/ai/generate_content \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Tech meetup", "action": "generate"}'
```

## Security Considerations

- CSRF tokens included in all AJAX requests
- Error handling for failed AI requests
- User feedback for loading and error states
- Disclaimer about AI-generated content accuracy

## Mobile-First Design

All styles follow mobile-first approach:

- Base styles optimized for mobile
- Media queries enhance for desktop
- Touch-friendly button sizes
- Responsive typography

## Future Enhancements

1. Chat history persistence (database storage)
2. User authentication integration for personalized responses
3. Multi-language support
4. Advanced content formatting in AI Write
5. Voice input for chat
6. Analytics on AI usage
7. Fine-tuned LLM model for event-specific responses

## Testing

**Manual Testing Checklist**:

- [ ] Chat button appears on all pages
- [ ] Chat modal opens/closes correctly
- [ ] Quick options can be selected
- [ ] Messages send and display properly
- [ ] AI Write button appears on event forms
- [ ] Prompt input toggles correctly
- [ ] Generate/Enhance actions work
- [ ] Loading states display
- [ ] Mobile responsive (test < 600px)
- [ ] Error handling works
- [ ] CSRF protection active

## Troubleshooting

**Chat button not appearing**:

- Check `application.html.erb` includes chat partials
- Verify `chatbot.css` is loaded
- Check browser console for JS errors

**AI Write not working**:

- Ensure on event creation/edit page
- Check `events.css` is loaded
- Verify `chatbot.js` is loaded
- Check network tab for 404 on JS file

**Styles not applying**:

- Run `bin/rails assets:precompile`
- Restart Rails server
- Clear browser cache

## License

Part of EventEase platform - Internal use only
