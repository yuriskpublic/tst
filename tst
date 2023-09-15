---
- name: List Pull Requests and Retrieve Review Status
  hosts: localhost
  tasks:
    - name: Get GitHub Personal Access Token
      pause:
        prompt: "Enter your GitHub Personal Access Token (https://github.com/settings/tokens):"
      register: github_token

    - name: List Pull Requests
      uri:
        url: "https://api.github.com/repos/{{ github_owner }}/{{ github_repo }}/pulls"
        method: GET
        headers:
          Authorization: "token {{ github_token.user_input }}"
        status_code: 200
        body_format: json
      register: pull_requests_response

    - name: Debug Pull Requests
      debug:
        var: pull_requests_response.json

    - name: Initialize Output Array
      set_fact:
        pull_requests_with_reviews: []

    - name: Loop through Pull Requests
      loop: "{{ pull_requests_response.json }}"
      loop_control:
        loop_var: pull_request
      block:
        - name: Get Reviews for Pull Request
          uri:
            url: "https://api.github.com/repos/{{ github_owner }}/{{ github_repo }}/pulls/{{ pull_request.number }}/reviews"
            method: GET
            headers:
              Authorization: "token {{ github_token.user_input }}"
            status_code: 200
            body_format: json
          register: reviews_response

        - name: Debug Reviews for Pull Request
          debug:
            var: reviews_response.json

        - name: Check Mergeable and Approval in Reviews
          set_fact:
            mergeable: "{{ pull_request.mergeable | default(false) }}"
            approvals: "{{ reviews_response.json | json_query('[?state==`APPROVED`]') }}"
          when: mergeable is true and approvals | length > 0

        - name: Add Pull Request with Reviews to the List
          set_fact:
            pull_requests_with_reviews: "{{ pull_requests_with_reviews + [{'pull_request': pull_request, 'reviews': approvals}] }}"

    - name: Debug Pull Requests with Reviews
      debug:
        var: pull_requests_with_reviews
