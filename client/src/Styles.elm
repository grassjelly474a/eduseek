module Styles exposing (css)

import Html exposing (Html)


css : Html msg
css =
    Html.node "style" [] [ Html.text """
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: #f9fafb;
            color: #1f2937;
            margin: 0;
            padding: 40px 20px;
            line-height: 1.5;
            -webkit-font-smoothing: antialiased;
        }

        .container {
            max-width: 800px;
            margin: 0 auto;
        }

        h1 {
            font-size: 2.5rem;
            font-weight: 700;
            color: #111827;
            letter-spacing: -0.03em;
            margin-bottom: 24px;
            text-align: center;
        }

        /* Tabs Navigation */
        .tabs {
            display: flex;
            justify-content: center;
            gap: 8px;
            margin-bottom: 32px;
            border-bottom: 1px solid #e5e7eb;
            padding-bottom: 16px;
        }

        .tab-btn {
            background: none;
            border: none;
            color: #4b5563;
            padding: 10px 20px;
            font-size: 0.95rem;
            font-weight: 500;
            cursor: pointer;
            border-radius: 6px;
            transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .tab-btn:hover {
            color: #111827;
            background-color: #f3f4f6;
        }

        .tab-btn:disabled {
            color: #4f46e5;
            background-color: #e0e7ff;
            cursor: default;
        }

        /* Typography & Headings */
        h2 {
            font-size: 1.5rem;
            font-weight: 600;
            color: #111827;
            margin-bottom: 20px;
            letter-spacing: -0.02em;
        }

        h3 {
            font-size: 1.25rem;
            font-weight: 600;
            color: #111827;
            margin-bottom: 16px;
            letter-spacing: -0.01em;
        }

        h4 {
            font-size: 1.1rem;
            font-weight: 600;
            color: #1f2937;
            margin-bottom: 16px;
        }

        /* Search Section */
        .search-container {
            margin-bottom: 32px;
        }

        .search-bar {
            display: flex;
            gap: 12px;
            margin-bottom: 24px;
        }

        .search-input {
            flex: 1;
            padding: 12px 16px;
            font-size: 1rem;
            border: 1px solid #d1d5db;
            border-radius: 8px;
            background-color: #ffffff;
            transition: all 0.2s;
            color: #1f2937;
            font-family: inherit;
        }

        .search-input:focus {
            outline: none;
            border-color: #6366f1;
            box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.15);
        }

        /* Buttons styling */
        .btn {
            padding: 12px 20px;
            font-size: 0.95rem;
            font-weight: 500;
            border: 1px solid #d1d5db;
            border-radius: 8px;
            background-color: #ffffff;
            color: #374151;
            cursor: pointer;
            transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
            font-family: inherit;
        }

        .btn:hover:not(:disabled) {
            background-color: #f9fafb;
            border-color: #9ca3af;
        }

        .btn:active:not(:disabled) {
            transform: scale(0.98);
        }

        .btn:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }

        .btn-primary {
            background-color: #4f46e5;
            border-color: #4f46e5;
            color: #ffffff;
        }

        .btn-primary:hover:not(:disabled) {
            background-color: #4338ca;
            border-color: #4338ca;
        }

        .btn-danger {
            background-color: #ef4444;
            border-color: #ef4444;
            color: #ffffff;
        }

        .btn-danger:hover:not(:disabled) {
            background-color: #dc2626;
            border-color: #dc2626;
        }

        .btn-sm {
            padding: 6px 12px;
            font-size: 0.85rem;
            border-radius: 6px;
        }

        /* Messages & Statuses */
        .status-msg {
            font-size: 0.95rem;
            color: #4b5563;
            margin: 20px 0;
            padding: 14px 18px;
            border-radius: 8px;
            background-color: #f3f4f6;
            border-left: 4px solid #9ca3af;
        }

        .status-success {
            background-color: #ecfdf5;
            color: #065f46;
            border-left: 4px solid #10b981;
        }

        .status-error {
            background-color: #fef2f2;
            color: #991b1b;
            border-left: 4px solid #ef4444;
        }

        /* Search Results */
        .results-container {
            display: flex;
            flex-direction: column;
            gap: 20px;
            margin-top: 20px;
        }

        .search-hit {
            background-color: #ffffff;
            border: 1px solid #e5e7eb;
            border-radius: 10px;
            padding: 24px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
            transition: transform 0.2s, box-shadow 0.2s;
        }

        .search-hit:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 16px -2px rgba(0, 0, 0, 0.04), 0 2px 4px -2px rgba(0, 0, 0, 0.02);
        }

        .hit-title {
            font-size: 1.25rem;
            font-weight: 600;
            margin-bottom: 6px;
        }

        .hit-title a {
            color: #4f46e5;
            text-decoration: none;
            transition: color 0.15s;
        }

        .hit-title a:hover {
            color: #3730a3;
            text-decoration: underline;
        }

        .hit-url {
            font-size: 0.85rem;
            color: #6b7280;
            margin-bottom: 12px;
            word-break: break-all;
        }

        .hit-description {
            font-size: 0.95rem;
            color: #374151;
            margin-bottom: 14px;
        }

        .hit-snippet-container {
            font-size: 0.9rem;
            color: #4b5563;
            background-color: #f9fafb;
            padding: 12px 16px;
            border-radius: 6px;
            border: 1px solid #f3f4f6;
            margin-bottom: 14px;
        }

        .hit-snippet-label {
            font-weight: 600;
            color: #374151;
            margin-right: 4px;
        }

        mark {
            background-color: #fef08a;
            color: #854d0e;
            padding: 2px 4px;
            border-radius: 4px;
            font-weight: 500;
        }

        .hit-meta {
            font-size: 0.8rem;
            color: #9ca3af;
        }

        /* Admin Section Styling */
        .admin-section {
            background-color: #ffffff;
            border: 1px solid #e5e7eb;
            border-radius: 10px;
            padding: 24px;
            margin-bottom: 24px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
        }

        .admin-section-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }

        .admin-section-header h3 {
            margin-bottom: 0;
        }

        /* Table styling */
        .table-container {
            overflow-x: auto;
            margin-bottom: 16px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
            font-size: 0.9rem;
        }

        th {
            font-weight: 600;
            color: #374151;
            border-bottom: 2px solid #e5e7eb;
            padding: 12px;
            background-color: #f9fafb;
        }

        td {
            padding: 14px 12px;
            border-bottom: 1px solid #e5e7eb;
            color: #4b5563;
            vertical-align: middle;
        }

        tr:last-child td {
            border-bottom: none;
        }

        tr:hover td {
            background-color: #f9fafb;
        }

        /* Delete Inline Confirmation Prompt */
        .confirm-prompt {
            background-color: #fee2e2;
            padding: 6px 12px;
            border-radius: 6px;
            color: #991b1b;
            font-size: 0.85rem;
            font-weight: 500;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }

        /* Form Layouts */
        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
            margin-bottom: 16px;
        }

        .form-group {
            margin-bottom: 16px;
        }

        .form-group-full {
            grid-column: span 2;
        }

        .form-group label {
            display: block;
            font-size: 0.85rem;
            font-weight: 500;
            color: #374151;
            margin-bottom: 6px;
        }

        .form-input, .form-textarea {
            width: 100%;
            padding: 10px 12px;
            font-size: 0.9rem;
            border: 1px solid #d1d5db;
            border-radius: 6px;
            background-color: #ffffff;
            transition: all 0.2s;
            color: #1f2937;
            font-family: inherit;
        }

        .form-input:focus, .form-textarea:focus {
            outline: none;
            border-color: #6366f1;
            box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.15);
        }

        .form-textarea {
            resize: vertical;
        }

        /* Horizontal rule styling */
        hr {
            border: 0;
            border-top: 1px solid #e5e7eb;
            margin: 32px 0;
        }
    """]
