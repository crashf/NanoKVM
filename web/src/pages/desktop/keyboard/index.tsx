import { useEffect, useRef } from 'react';

import { client } from '@/lib/websocket.ts';

import { KeyboardCodes, ModifierCodes } from './mappings.ts';

export const Keyboard = () => {
  const lastCodeRef = useRef('');
  const modifierRef = useRef({
    ctrl: 0,
    shift: 0,
    alt: 0,
    meta: 0
  });

  // listen keyboard events
  useEffect(() => {
    const modifiers = ['Control', 'Shift', 'Alt', 'Meta'];

    // Check if the event target is an input element that should receive keyboard input
    function shouldIgnoreEvent(event: KeyboardEvent): boolean {
      const target = event.target as HTMLElement;
      const tagName = target.tagName.toLowerCase();
      
      // Allow typing in input fields, textareas, and contenteditable elements
      return (
        tagName === 'input' ||
        tagName === 'textarea' ||
        target.isContentEditable ||
        target.getAttribute('contenteditable') === 'true'
      );
    }

    window.addEventListener('keydown', handleKeyDown);
    window.addEventListener('keyup', handleKeyUp);

    // press button
    function handleKeyDown(event: KeyboardEvent) {
      // Don't intercept if user is typing in an input field
      if (shouldIgnoreEvent(event)) {
        return;
      }

      disableEvent(event);

      lastCodeRef.current = event.code;

      if (modifiers.includes(event.key)) {
        const code = ModifierCodes.get(event.code)!;
        setModifier(event.key, code);

        if (event.key === 'Meta') {
          return;
        }
      }

      sendKeyDown(event);
    }

    // release button
    function handleKeyUp(event: KeyboardEvent) {
      // Don't intercept if user is typing in an input field
      if (shouldIgnoreEvent(event)) {
        return;
      }

      disableEvent(event);

      if (modifiers.includes(event.key)) {
        if (event.key === 'Meta' && lastCodeRef.current === event.code) {
          sendKeyDown(event, true);
          sendKeyUp();
        }

        setModifier(event.key, 0);
      }

      if (event.key !== 'Meta') {
        sendKeyUp();
      }
    }

    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      window.removeEventListener('keyup', handleKeyUp);
    };
  }, []);

  function setModifier(key: string, code: number) {
    switch (key) {
      case 'Control':
        modifierRef.current.ctrl = code;
        break;
      case 'Alt':
        modifierRef.current.alt = code;
        break;
      case 'Shift':
        modifierRef.current.shift = code;
        break;
      case 'Meta':
        modifierRef.current.meta = code;
        break;
      default:
        console.log('unknown key: ', key);
    }
  }

  function sendKeyDown(event: KeyboardEvent, isMeta?: boolean) {
    const code = KeyboardCodes.get(event.code);
    if (!code) {
      console.log('unknown code: ', event.code);
      return;
    }

    const ctrl = event.ctrlKey ? modifierRef.current.ctrl || 1 : 0;
    const shift = event.shiftKey ? modifierRef.current.shift || 2 : 0;
    const alt = event.altKey ? modifierRef.current.alt || 4 : 0;
    const meta = event.metaKey || isMeta ? modifierRef.current.meta || 8 : 0;

    client.send([1, code, ctrl, shift, alt, meta]);
  }

  function sendKeyUp() {
    client.send([1, 0, 0, 0, 0, 0]);
  }

  // disable the default keyboard events
  function disableEvent(event: KeyboardEvent) {
    event.preventDefault();
    event.stopPropagation();
  }

  return <></>;
};
