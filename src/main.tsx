import React from "react";
import ReactDOM from "react-dom/client";
import { Tldraw } from '@tldraw/tldraw'
import "@tldraw/tldraw/editor.css";
import "@tldraw/tldraw/ui.css";
import "./styles.css";

ReactDOM.createRoot(document.getElementById("app") as HTMLElement).render(
  <React.StrictMode>
		<div
			style={{
				position: 'fixed',
				inset: 0,
			}}
		>
			<Tldraw />
		</div>
  </React.StrictMode>
);
