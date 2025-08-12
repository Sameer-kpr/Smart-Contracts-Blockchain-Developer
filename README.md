# Smart-Contracts-Blockchain-Developer
1. 1.Install deps
2. ```bash
3. npm install
4. 2.Compile
5. npx hardhat compile
6. 3.Run a Hardhat mode in one terminal
7. npx hardhat node
8. 4.Deploy to local network(new terminal)
9. npx hardhat run scripts/deploy.js
10. --network localhost
11. 5.Copy deployed addresses into backend/.env then run backend
12. cd backend
13. cp .env.example .env
14. node index.js
15. 6.Open frontend/index.html(serve via simple http server) and interact
16. python3 -m http.server 8080
17. #open
18. http://localhost:8080/frontend/index.html
