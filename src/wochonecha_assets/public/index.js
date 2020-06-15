import wochonecha from 'ic:canisters/wochonecha';

wochonecha.greet(window.prompt("Enter your name:")).then(greeting => {
  window.alert(greeting);
});
