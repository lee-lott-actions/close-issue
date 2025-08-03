const express = require('express');
const app = express();
app.use(express.json());

app.patch('/repos/:owner/:repo/issues/:issue_number', (req, res) => {
  console.log(`Mock intercepted: PATCH /repos/${req.params.owner}/${req.params.repo}/issues/${req.params.issue_number}`);
  console.log('Request body:', JSON.stringify(req.body));
  console.log('Request headers:', JSON.stringify(req.headers));

  // Validate the Authorization header
  if (!req.headers.authorization || !req.headers.authorization.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Unauthorized: Missing or invalid Bearer token' });
  }

  // Validate the request body
  if (req.body.state === 'closed') {
    // Simulate response based on parameters
    if (
      req.params.owner === 'test-owner' &&
      req.params.repo === 'test-repo' &&
      req.params.issue_number === '1'
    ) {
      res.status(200).json({ state: 'closed' });
    } else {
      res.status(404).json({ message: 'Issue not found' });
    }
  } else {
    res.status(400).json({ message: 'Invalid request: state must be "closed"' });
  }
});

app.listen(3000, () => {
  console.log('Mock server listening on http://127.0.0.1:3000...');
});
