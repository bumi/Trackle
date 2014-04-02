<div class="entry-body">

  <div class="header">
    <span class='project' style="background-color:{{ m.projectColor() }};">
      {{ m.project && m.project.name }}
    </span>

    <span class='minutes'>
      {{ m.minutes / 60 }}
    </span>
  </div>

  <% var tags = m.tags() %>
  <% for(var tag in tags) { %>
      <div class='description'>{{ tags[tag] }}</div>
  <% } %>

</div>
