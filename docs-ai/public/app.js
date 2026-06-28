const form = document.querySelector('#chat-form');
const input = document.querySelector('#question');
const submit = document.querySelector('#submit');
const conversation = document.querySelector('#conversation');

if (new URLSearchParams(window.location.search).has('embed')) {
  document.body.classList.add('embedded');
}

function addMessage(kind, text, sources = []) {
  const message = document.createElement('div');
  message.className = `message ${kind}`;
  const body = document.createElement('p');
  body.textContent = text;
  message.append(body);

  if (sources.length) {
    const list = document.createElement('ul');
    list.className = 'sources';
    for (const source of sources) {
      const item = document.createElement('li');
      const link = document.createElement('a');
      link.href = source.url;
      link.target = '_blank';
      link.rel = 'noreferrer';
      link.textContent = `${source.title} — ${source.heading}`;
      item.append(link);
      list.append(item);
    }
    message.append(list);
  }

  conversation.append(message);
  message.scrollIntoView({behavior: 'smooth', block: 'end'});
}

async function ask(question) {
  addMessage('user', question);
  submit.disabled = true;
  submit.textContent = 'Thinking…';
  input.value = '';

  try {
    const response = await fetch('/api/chat', {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify({question}),
    });
    const result = await response.json();
    if (!response.ok) throw new Error(result.error || 'Request failed.');
    addMessage('assistant', result.answer, result.sources || []);
  } catch (error) {
    addMessage('assistant error', error.message || 'The assistant is temporarily unavailable.');
  } finally {
    submit.disabled = false;
    submit.textContent = 'Ask';
    input.focus();
  }
}

form.addEventListener('submit', (event) => {
  event.preventDefault();
  const question = input.value.trim();
  if (question) ask(question);
});

for (const suggestion of document.querySelectorAll('.suggestions button')) {
  suggestion.addEventListener('click', () => ask(suggestion.textContent));
}

input.addEventListener('keydown', (event) => {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault();
    form.requestSubmit();
  }
});
