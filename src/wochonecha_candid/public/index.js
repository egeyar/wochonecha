import canister from 'ic:canisters/wochonecha';
import { IDL, UI } from '@dfinity/agent';

const CSS = `
.signature {
    font-size: 15px;
    font-weight: 400;
    margin: 5px;
}
.argument, .result, .status, .composite {
    background-color: #F9F9F9;
    border: 1px solid #E5E5E5;
    color: #545454;
    font-family: monospace;
    font-size: 15px;
    font-weight: 400;          
    height: auto;
    margin-right: 10px;
    margin-bottom: 10px;
}
.open {
    margin: 5px;
}
.reject {
    border: 1px solid #cc0000;
}
.result {
    display: none;
}
.error {
    color: #cc0000;
}
.status {
    color: #cc0000;
    display: none;
}
.left {
    text-align: left;
    width: 84%;
    display: inline-block;
    overflow-wrap: break-word;
}
.right {
    text-align: right;
    width: 15%;
    display: inline-block;
}
.btn {
    background-color: #02ADEA;
    border-color: #02ADEA;
    border-radius: .25rem;
    color: #FFF;
    font-family: sans-serif;
    font-size: 16px;
    font-weight: 700;
    margin: 5px;
}
.popup-form {
    border: 1px solid #E5E5E5;
    padding-top: 10px;
    padding-left: 10px;
}
.console {
    display: flex;
    flex: 1;
    flex-direction: column;
    font-family: monospace;
    background-color: #F9F9F9;
    color: #545454;
}
.console-line {
    overflow-wrap: break-word;
    flex: 0;
    flex-basis: auto;
    border: 0;
    margin-left: 5px;
    margin-bottom: 5px;
}
`;

const HTML = `
    <h1 id="title">Welcome to DUAL!</h1>
    <div>
      This service has the following methods:
      <ul id="methods">
      </ul>
    </div>
`;

function render(id, canister) {
  for (const [name, func] of Object.entries(canister.__actorInterface())) {
    renderMethod(name, func, canister[name]);
  }
  const console = document.createElement("div");
  console.className = 'console';
  document.body.appendChild(console);
}

function renderMethod(name, idl_func, f) {
  const item = document.createElement("li");

  const sig = document.createElement("div");
  sig.className = 'signature';
  sig.innerHTML = `${name}: ${idl_func.display()}`;
  item.appendChild(sig);

  const inputs = [];
  idl_func.argTypes.forEach((arg, i) => {
    const inputbox = UI.renderInput(arg);
    inputs.push(inputbox);
    inputbox.render(item);
  });

  const button = document.createElement("button");
  button.className = 'btn';
  if (idl_func.annotations.includes('query')) {
    button.innerText = 'Query';
  } else {
    button.innerText = 'Call';
  }
  item.appendChild(button);

  const random = document.createElement("button");
  random.className = 'btn';
  random.innerText = 'Lucky';
  item.appendChild(random);

  const result_div = document.createElement("div");
  result_div.className = 'result';
  const left = document.createElement("span");
  left.className = 'left';
  const right = document.createElement("span");
  right.className = 'right';
  result_div.appendChild(left);
  result_div.appendChild(right);
  item.appendChild(result_div);

  const list = document.getElementById("methods");
  list.append(item);

  async function call(args) {
    left.className = 'left';
    left.innerText = 'Waiting...';
    right.innerText = ''
    result_div.style.display = 'block';

    const t_before = Date.now();
    const result = await f.apply(null, args);
    const duration = (Date.now() - t_before)/1000;
    right.innerText = `(${duration}s)`;
    return result;
  }

  function callAndRender(args) {
    (async () => {
      const call_result = await call(args);
      let result;
      if (idl_func.retTypes.length === 0) {
        result = [];
      } else if (idl_func.retTypes.length === 1) {
        result = [call_result];
      } else {
        result = call_result;
      }
      left.innerHTML = '';

      const containers = [];
      const text_container = document.createElement('div');
      containers.push(text_container);
      left.appendChild(text_container);
      const text = encodeStr(IDL.FuncClass.argsToString(idl_func.retTypes, result));
      text_container.innerHTML = text;
      const show_args = encodeStr(IDL.FuncClass.argsToString(idl_func.argTypes, args));
      log(`› ${name}${show_args}`);
      log(text);

      const ui_container = document.createElement('div');
      containers.push(ui_container);
      ui_container.style.display = 'none';
      left.appendChild(ui_container);
      idl_func.retTypes.forEach((arg, i) => {
        const box = UI.renderInput(arg);
        box.render(ui_container);
        UI.renderValue(arg, box, result[i]);
      });

      const json_container = document.createElement('div');
      containers.push(json_container);
      json_container.style.display = 'none';
      left.appendChild(json_container);
      json_container.innerText = JSON.stringify(call_result);

      let i = 0;
      left.addEventListener('click', () => {
        containers[i].style.display = 'none';
        i = (i + 1) % 3;
        containers[i].style.display = 'block';
      });
    })().catch(err => {
      left.className += ' error';
      left.innerText = err.message;
      throw err;
    })
  }

  random.addEventListener("click", function() {
    const args = inputs.map(arg => arg.parse({ random: true }));
    const isReject = inputs.some(arg => arg.isRejected());
    if (isReject) {
      return;
    }
    callAndRender(args);
  });

  button.addEventListener("click", function() {
    const args = inputs.map(arg => arg.parse());
    const isReject = inputs.some(arg => arg.isRejected());
    if (isReject) {
      return;
    }
    callAndRender(args);
  });
}

function encodeStr(str) {
  const escapeChars = {
    ' ' : '&nbsp;',
    '<' : '&lt;',
    '>' : '&gt;',
    '\n' : '<br>',
  };
  const regex = new RegExp('[ <>\n]', 'g');
  return str.replace(regex, m => {
    return escapeChars[m];
  });
}

function log(content) {
  const console = document.getElementsByClassName("console")[0];
  const line = document.createElement("div");
  line.className = 'console-line';
  if (content instanceof Element) {
    line.appendChild(content);
  } else {
    line.innerHTML = content;
  }
  console.appendChild(line);
}

// Bootstrapping.
let styleEl = document.createElement("style");
styleEl.innerText = CSS;
document.head.append(styleEl);

document.getElementById("app").innerHTML = HTML;

render(canister.__canisterId(), canister);
