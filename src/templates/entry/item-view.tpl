<div class='project'>

  <div class="project-color" style="background-color: {{ m.projectColor() }};"></div>
  <div class="project-name">{{ m.project && m.project.name }}</div>

</div>

<% if (m.minutes > 60) { %>
  <% var tags = m.tags() %>
  <ul class="tag-list">
    <% for (var tag in tags) { %>
        <li class='tag'>{{ tags[tag] }}</li>
    <% } %>
  </ul>
<% } %>

<div class="drag-border"></div>
