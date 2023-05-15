# Projet_fil_rouge

Lien trello : https://trello.com/b/FEUWW3Kn/supply


## I. Utilisation


### <u> 1. Installation </u>

```
- Ganache : https://trufflesuite.com/ganache/
- VsCode Extension : https://marketplace.visualstudio.com/items?itemName=JuanBlanco.solidity
```


### <u> 2. Lancement </u>

```
- Lancer Ganache : Quickstart
- A droite de VsCode, cliquer sur "Ethereum Remix"
- Dans Remix, cliquer sur "Compiler" puis choisissiez le fichier "Contracts/storage.sol"
- Cliquer sur "Run & Deploy" puis choisissiez l'options "Activate"
- Ajouter le port utilisé par Ganache dans le champ "Port" (ex : http://127.0.0.1:7545) puis cliquer sur "Connect"
- Définissez le gas limit à 30000000 et cliquer sur "Deploy"
- Ouvrez le menu "contract address" que vous venez de déployer
```

<br>

## II. Mise en place du projet


### <u> 1. Smart Contract </u>

#### **A. Introduction**

Création d'un smart contract Ethereum qui contiendra toutes les informations pertinentes sur notre stock d'approvisionnement, telles que les quantités, les prix et les dates d'achat. Utilisation du langage de programmation Solidity pour créer le contrat.

#### **B. Détails**

Pour créer un smart contract Ethereum, nous avons fait le choix d'utiliser le langage de programmation Solidity. Utilisation de Remix (extension VScode) pour écrire le contrat.

Voici les étapes générales pour créer un smart contract Ethereum :

- Déterminer les fonctions que nous souhaitons inclure dans le contrat.
- Écrire le code Solidity pour chaque fonction.
- Compiler le contrat pour vérifier qu'il n'y a pas d'erreurs.
- Déploiement du contrat sur la blockchain Ethereum en local avec Ganache.
- Une fois que le contrat est déployé, nous pouvons interagir avec lui en appelant ses fonctions depuis une interface utilisateur ou un autre contrat.


### <u> 2. Définir les autorisations </u>

#### **A. Introduction**

Définition des autorisations pour le smart contract, de sorte que seules certaines parties puissent y accéder. Par exemple, Permettre aux fournisseurs d'ajouter des informations sur les produits qu'ils ont fournis, tandis que les clients pourront simplement afficher les informations stockées dans le contrat mais n'auront pas la possibilité de modifier cette partie.

#### **B. Détails**

Pour définir les autorisations dans le smart contract, nous utilisons des modificateurs Solidity. Les modificateurs permettent de restreindre l'accès à certaines fonctions à des utilisateurs spécifiques.

Par exemple, créer un modificateur qui vérifie si l'utilisateur qui appelle la fonction est un fournisseur enregistré. Si l'utilisateur n'est pas un fournisseur, la fonction ne sera pas exécutée.

Voici un exemple de modificateur qui vérifie si l'utilisateur est un fournisseur :

```javascript
modifier onlySupplier() {
  require(keccak256(bytes(users[msg.sender].role)) == keccak256(bytes("supplier")), "You are not authorized to access this function.");
  _;
}
```

- Les fournisseurs sont les seuls à pouvoir ajouter, modifier, supprimer des produits dans le smart contract.
- Les clients ont un accès restreint au smart contract, ils peuvent seulement acheter des produits et afficher les informations stockées dans le contrat.

### <u> 3. Stocker les informations sur la blockchain </u>


#### **A. Introduction**

Une fois que le smart contract crée, nous pouvons commencer à stocker les informations sur la blockchain Ethereum. Toutes les informations que nous allons stocker sur la blockchain seront immuables et ne pourront pas être modifiées ou supprimées.

#### **B. Détails**

Pour stocker les informations sur la blockchain Ethereum, nous allons appeler les fonctions de notre smart contrat. Lorsque nous allons appeler une fonction, nous devrons payer des frais de transaction en gas, qui est la mesure de l'utilisation des ressources de la blockchain Ethereum.

Voici un exemple de fonction qui stocke des informations sur la blockchain Ethereum :

```javascript
function addProduct(string memory name, uint256 quantity, uint256 price) public onlySupplier() {
  // [...] code //
  id++;
  string memory companySupplier = users[msg.sender].companyName;
  uint256 date = block.timestamp;
  Product memory newProduct = Product(id, name, quantity, price, date, companySupplier);
  products[id] = newProduct;
}
```

Dans cet exemple, addProduct() ajoute un produit à un tableau products dans le smart contract Ethereum. Le tableau products contient des structures Product, qui contiennent les informations sur chaque produit.


### <u> 4. Utiliser des tokens Ethereum </u>


**_Implémentation de notre propre token Eth à venir_**


#### **A. Introduction**

Utiliser des tokens Ethereum: Nous allons également utiliser des tokens Ethereum pour suivre la possession de notre stock d'approvisionnement. Chaque fois que nous achetons ou vendons des produits, nous pourrons transférer des tokens Ethereum en échange.

#### **B. Détails**

Pour utiliser des tokens Ethereum pour suivre la possession de notre stock d'approvisionnement, nous allons créer notre propre token ERC-20. ERC-20 est un standard pour les tokens Ethereum qui définit les fonctions et les événements que tout token ERC-20 doit implémenter.

Voici comment créer un token ERC-20 pour notre application :

1. Définir les propriétés du token : Nous allons définir des propriétés telles que le nom, le symbole, le nombre total de tokens en circulation et le nombre de décimales du token.

```javascript
contract ERC20 {
  string public name = "ObsidianToken";
  string public symbol = "OBST";
  uint8 public decimals = 18;
  uint256 public totalSupply = 1000000000;

  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  // [...]
```

Dans cet exemple, nous avons créé un token appelé "ObsidianToken" avec le symbole "OBST", avec un total de 1 milliard de tokens en circulation.


2. Ajout de fonctions de transfert : Nous avons ajouté des fonctions pour transférer des tokens entre les adresses Ethereum. Nous utiliserons les fonctions standard transfer et transferFrom définies dans l'interface ERC-20.

```javascript
function transfer(address to, uint256 value) public returns (bool success) {
  require(balanceOf[msg.sender] >= value, "Insufficient balance");
  balanceOf[msg.sender] -= value;
  balanceOf[to] += value;
  emit Transfer(msg.sender, to, value);
  return true;
}

function transferFrom(address from, address to, uint256 value) public returns (bool success) {
  require(value <= balanceOf[from], "Insufficient balance");
  require(value <= allowance[from][msg.sender], "Allowance exceeded");
  balanceOf[from] -= value;
  balanceOf[to] += value;
  allowance[from][msg.sender] -= value;
  emit Transfer(from, to, value);
  return true;
}
```

3. <strong>Déployer le contrat du token sur la blockchain Ethereum</strong> : Une fois que nous avons écrit le code pour notre token ERC-20, nous pourrons le déployer sur la blockchain Ethereum en utilisant un portefeuille compatible avec Ethereum comme MetaMask ou MyEtherWallet. Nous utilserons Remix (extension VScode) pour déployer notre contrat.

4. <strong>Utiliser le token dans notre contrat d'approvisionnement</strong> : Quand nous aurons déployé notre token ERC-20, nous pourrons l'utiliser dans notre contrat d'approvisionnement pour suivre la possession de notre stock. Chaque fois que nous allons acheter ou vendre des produits, nous pourrons transférer des tokens Ethereum en échange. Nous allons utiliser la fonction transfer définie dans notre contrat ERC-20 pour transférer des tokens entre les adresses Ethereum.
